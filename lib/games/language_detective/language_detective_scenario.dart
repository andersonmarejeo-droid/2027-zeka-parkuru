import 'dart:math' as math;

import '../shared/content_seed.dart';

class DetectiveCase {
  const DetectiveCase({
    required this.id,
    required this.minimumStage,
    required this.sourceTr,
    required this.sourceEn,
    required this.passageTr,
    required this.passageEn,
    required this.questionTr,
    required this.questionEn,
    required this.optionsTr,
    required this.optionsEn,
    required this.correctOptionIndex,
    required this.evidenceTr,
    required this.evidenceEn,
    required this.explanationTr,
    required this.explanationEn,
  });

  final String id;
  final int minimumStage;
  final String sourceTr;
  final String sourceEn;
  final String passageTr;
  final String passageEn;
  final String questionTr;
  final String questionEn;
  final List<String> optionsTr;
  final List<String> optionsEn;
  final int correctOptionIndex;
  final String evidenceTr;
  final String evidenceEn;
  final String explanationTr;
  final String explanationEn;
}

class DetectiveBoardCase {
  const DetectiveBoardCase({required this.caseFile, required this.optionOrder});

  final DetectiveCase caseFile;
  final List<int> optionOrder;

  int get correctOptionIndex =>
      optionOrder.indexOf(caseFile.correctOptionIndex);
}

/// Evidence-reading scenarios. Each question has a traceable passage cue and
/// exactly one conclusion supported by that cue.
class LanguageDetectiveScenario {
  const LanguageDetectiveScenario({
    required this.stage,
    required this.cases,
    required this.isPractice,
    required this.round,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;

  static const List<DetectiveCase> _bank = <DetectiveCase>[
    DetectiveCase(
      id: 'polite_window_request',
      minimumStage: 1,
      sourceTr: 'Koridor notu',
      sourceEn: 'Hallway note',
      passageTr: 'Oda havasızdı. Mert pencereye bakıp “İçerisi biraz ağırlaştı,” dedi.',
      passageEn: 'The room felt stuffy. Mert looked at the window and said, “The air is getting a little heavy.”',
      questionTr: 'Mert’in sözünün en olası amacı nedir?',
      questionEn: 'What is Mert most likely trying to do?',
      optionsTr: <String>[
        'Birinin pencereyi açmasını nazikçe istemek.',
        'Odanın sıcaklığını ölçtüğünü bildirmek.',
        'Pencerenin kırıldığını haber vermek.',
        'Konuşmayı bitirmek istediğini söylemek.',
      ],
      optionsEn: <String>[
        'Politely suggest that someone open the window.',
        'Report that he measured the room temperature.',
        'Warn that the window is broken.',
        'Say that he wants to end the conversation.',
      ],
      correctOptionIndex: 0,
      evidenceTr:
          'Mert pencereye bakarken odanın havasız olduğundan yakınıyor.',
      evidenceEn: 'He looks at the window while commenting on the stuffy air.',
      explanationTr:
          'Doğrudan emir vermese de bakışı ve bağlamı bir rica ima ediyor.',
      explanationEn:
          'The setting and glance make the indirect comment a request.',
    ),
    DetectiveCase(
      id: 'protect_the_book',
      minimumStage: 1,
      sourceTr: 'Yağmurlu durak',
      sourceEn: 'Rainy bus stop',
      passageTr: 'Yağmur başlayınca Ece çantasından poşet çıkardı ve kitabını onunla örttü.',
      passageEn: 'When rain started, Ece took a bag from her backpack and covered her book with it.',
      questionTr: 'Ece’nin davranışından hangi sonuç çıkar?',
      questionEn: 'What can be inferred from Ece’s action?',
      optionsTr: <String>[
        'Kitabının ıslanmasını önlemek istiyor.',
        'Otobüsün rotasını değiştirmeye çalışıyor.',
        'Yağmurun dinmesini bekliyor.',
        'Kitabı birine vermeyi planlıyor.',
      ],
      optionsEn: <String>[
        'She is trying to keep her book dry.',
        'She is trying to change the bus route.',
        'She is waiting for the rain to stop.',
        'She plans to give the book away.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Poşeti özellikle kitabının üzerine örtüyor.',
      evidenceEn: 'She places the bag over the book specifically.',
      explanationTr: 'Eylem, kitabı yağmurdan korumaya yönelik; başka bir amaç belirtilmiyor.',
      explanationEn:
          'The action protects the book from rain; no other purpose is stated.',
    ),
    DetectiveCase(
      id: 'checkable_fact',
      minimumStage: 1,
      sourceTr: 'Okul duyurusu',
      sourceEn: 'School notice',
      passageTr: 'Sergi cuma günü saat 18.00’de açılıyor. Öğrenci konseyi, bunun yılın en güzel etkinliği olacağını düşünüyor.',
      passageEn: 'The exhibition opens Friday at 6 p.m. The student council thinks it will be the best event of the year.',
      questionTr: 'Metindeki hangi ifade doğrudan doğrulanabilir bir olgudur?',
      questionEn: 'Which statement is a directly checkable fact?',
      optionsTr: <String>[
        'Sergi cuma saat 18.00’de açılıyor.',
        'Sergi yılın en güzel etkinliğidir.',
        'Bütün öğrenciler sergiyi sevecek.',
        'Konseyin seçimi kusursuzdur.',
      ],
      optionsEn: <String>[
        'The exhibition opens Friday at 6 p.m.',
        'The exhibition is the best event of the year.',
        'Every student will like the exhibition.',
        'The council made a perfect choice.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Gün ve saat gözlem ya da kayıtla kontrol edilebilir.',
      evidenceEn: 'The date and time can be checked against a schedule.',
      explanationTr: '“En güzel” bir değerlendirmedir; açılış saati ise ölçülebilir bilgidir.',
      explanationEn: '“Best” is an opinion; the opening time is measurable.',
    ),
    DetectiveCase(
      id: 'late_departure',
      minimumStage: 1,
      sourceTr: 'Sabah kaydı',
      sourceEn: 'Morning log',
      passageTr: 'Can evden her zamankinden on dakika geç çıktı. Durağa vardığında otobüs çoktan ayrılmıştı.',
      passageEn: 'Can left home ten minutes later than usual. By the time he reached the stop, the bus had already left.',
      questionTr: 'Otobüsü kaçırmasını en iyi hangi açıklama destekler?',
      questionEn:
          'Which explanation is best supported for why he missed the bus?',
      optionsTr: <String>[
        'Evden geç çıkması durağa geç varmasına yol açtı.',
        'Otobüs o gün çalışmıyordu.',
        'Can yanlış otobüse bindi.',
        'Durağın yeri değişmişti.',
      ],
      optionsEn: <String>[
        'Leaving late caused him to reach the stop too late.',
        'The bus did not run that day.',
        'Can boarded the wrong bus.',
        'The bus stop had moved.',
      ],
      correctOptionIndex: 0,
      evidenceTr:
          'Geç çıkış ve otobüsün çoktan ayrılmış olması sırayla veriliyor.',
      evidenceEn: 'The late departure and the bus already being gone are linked in time.',
      explanationTr: 'Metin, geç çıkış ile kaçırılan otobüs arasında açık bir zaman ilişkisi kuruyor.',
      explanationEn:
          'The passage directly connects his late start with the missed bus.',
    ),
    DetectiveCase(
      id: 'limited_offer',
      minimumStage: 1,
      sourceTr: 'Mağaza afişi',
      sourceEn: 'Store poster',
      passageTr: 'Afişte “Yalnızca bugün yüzde 20 indirim — stoklarla sınırlı” yazıyor.',
      passageEn: 'A poster reads, “20% off today only — while stocks last.”',
      questionTr: 'Afişten kesin olarak çıkarılamayacak ifade hangisidir?',
      questionEn: 'Which claim cannot be concluded from the poster?',
      optionsTr: <String>[
        'İndirimin gelecek hafta da süreceği.',
        'İndirim oranının yüzde 20 olduğu.',
        'Teklifin bugün için duyurulduğu.',
        'Ürün miktarının sınırlı olabileceği.',
      ],
      optionsEn: <String>[
        'The discount will continue next week.',
        'The discount rate is 20%.',
        'The offer is advertised for today.',
        'The available quantity may be limited.',
      ],
      correctOptionIndex: 0,
      evidenceTr: '“Yalnızca bugün” ifadesi teklifin süresini sınırlar.',
      evidenceEn: '“Today only” limits when the offer applies.',
      explanationTr: 'Gelecek haftaya uzatıldığına dair bir bilgi yok; afiş tersine süre sınırı koyuyor.',
      explanationEn: 'Nothing extends the offer into next week; the wording limits it to today.',
    ),
    DetectiveCase(
      id: 'due_date_receipt',
      minimumStage: 3,
      sourceTr: 'Kütüphane fişi',
      sourceEn: 'Library receipt',
      passageTr: 'Kitabın son teslim günü salıydı. Rana kitabı çarşamba iade etti ve görevli teslim fişi verdi.',
      passageEn: 'The book was due Tuesday. Rana returned it on Wednesday and received a return slip.',
      questionTr: 'Metin hangi bilgiyi destekliyor?',
      questionEn: 'Which detail is supported by the passage?',
      optionsTr: <String>[
        'Kitap, son teslim gününden bir gün sonra iade edildi.',
        'Rana kitabı salı günü iade etti.',
        'Kütüphane gecikme ücreti almadı.',
        'Görevli kitabı teslim almayı reddetti.',
      ],
      optionsEn: <String>[
        'The book was returned one day after its due date.',
        'Rana returned the book on Tuesday.',
        'The library charged no late fee.',
        'The librarian refused the return.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Salı son gün; iade çarşamba yapılmış.',
      evidenceEn: 'Tuesday is the due date; the return happened Wednesday.',
      explanationTr: 'Ücret ya da görevlinin tutumu hakkında bilgi verilmediğinden yalnız tarih ilişkisi kesindir.',
      explanationEn: 'No fee or refusal is mentioned, so only the date relationship is certain.',
    ),
    DetectiveCase(
      id: 'one_floor_survey',
      minimumStage: 3,
      sourceTr: 'Apartman anketi',
      sourceEn: 'Apartment survey',
      passageTr: 'Birinci kattaki dairelerin yüzde 60’ı yeni bisiklet parkını destekledi. Anket diğer katlara dağıtılmadı.',
      passageEn: 'Sixty percent of first-floor residents supported a new bike rack. The survey was not sent to other floors.',
      questionTr: 'Sonuç hangi gruba genellenebilir?',
      questionEn: 'To which group can the result be generalized?',
      optionsTr: <String>[
        'Yalnızca ankete katılan birinci kat sakinlerine.',
        'Apartmandaki bütün sakinlere.',
        'Şehirde yaşayan tüm bisikletçilere.',
        'Anketi görmeyen diğer katlara.',
      ],
      optionsEn: <String>[
        'Only the first-floor residents who answered.',
        'Every resident in the building.',
        'All cyclists in the city.',
        'The other floors that were not surveyed.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Örneklem yalnız birinci kattaki dairelerden oluşuyor.',
      evidenceEn: 'The sample includes only first-floor apartments.',
      explanationTr:
          'Diğer katlar ölçülmediği için sonuç tüm binayı temsil etmiyor.',
      explanationEn: 'Because other floors were not measured, the result does not represent the whole building.',
    ),
    DetectiveCase(
      id: 'unverified_post',
      minimumStage: 3,
      sourceTr: 'Paylaşım taslağı',
      sourceEn: 'Draft post',
      passageTr: 'Bir blog yeni köprünün cuma açılacağını yazdı. Yazar, duyuruyu belediyeden doğrulamadığını da ekledi.',
      passageEn: 'A blog says the new bridge will open Friday. The writer adds that they have not verified the notice with the city.',
      questionTr: 'Okur en uygun olarak ne yapmalıdır?',
      questionEn: 'What is the most appropriate next step for a reader?',
      optionsTr: <String>[
        'Açılış tarihini belediyenin resmî duyurusundan kontrol etmek.',
        'Tarihi kesin bilgi gibi herkese iletmek.',
        'Köprünün iptal edildiğini varsaymak.',
        'Blog yazarının kötü niyetli olduğuna karar vermek.',
      ],
      optionsEn: <String>[
        'Check the date against an official city notice.',
        'Share the date as confirmed fact.',
        'Assume the bridge has been cancelled.',
        'Decide that the blogger is acting maliciously.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Yazar doğrulama yapmadığını açıkça söylüyor.',
      evidenceEn: 'The writer explicitly says the claim has not been verified.',
      explanationTr: 'Doğrulanmamış bir iddiayı reddetmek de onaylamak da yerine, güvenilir kaynaktan kontrol etmek gerekir.',
      explanationEn: 'An unverified claim should be checked, not accepted or rejected without evidence.',
    ),
    DetectiveCase(
      id: 'member_discount',
      minimumStage: 3,
      sourceTr: 'Üyelik teklifi',
      sourceEn: 'Membership offer',
      passageTr:
          'Kasadaki not: “Üyelere, 500 TL üzeri alışverişte yüzde 10 indirim.”',
      passageEn:
          'A checkout note says, “Members get 10% off purchases over \$50.”',
      questionTr: 'Teklif hangi koşulda uygulanır?',
      questionEn: 'Under what condition does the offer apply?',
      optionsTr: <String>[
        'Alıcı üye olmalı ve alışveriş 500 TL’yi aşmalı.',
        'Her alıcı tek ürün alsa da indirim kazanır.',
        'Alışveriş tam 500 TL olmalıdır.',
        'Üye olmayanlar yüzde 10 daha fazla öder.',
      ],
      optionsEn: <String>[
        'The buyer must be a member and spend more than \$50.',
        'Every buyer gets the discount on any single item.',
        'The purchase must equal exactly \$50.',
        'Nonmembers pay 10% more.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Notta hem üyelik hem de 500 TL üzeri harcama koşulu var.',
      evidenceEn: 'The note states both membership and a spending threshold.',
      explanationTr:
          '“Üzerinde” ifadesi tam 500 TL’yi değil, daha yüksek tutarı kapsar.',
      explanationEn:
          '“Over” means greater than the threshold, not exactly equal to it.',
    ),
    DetectiveCase(
      id: 'repeated_late_thanks',
      minimumStage: 3,
      sourceTr: 'İş yazışması',
      sourceEn: 'Work message',
      passageTr:
          '“Raporu yine teslim tarihinden sonra gönderdiğin için teşekkürler.”',
      passageEn: '“Thanks for sending the report after the deadline again.”',
      questionTr: 'Cümlenin tonu en iyi nasıl tanımlanır?',
      questionEn: 'How is the tone best described?',
      optionsTr: <String>[
        'Hafif sitemli ve alaycı.',
        'Tamamen tarafsız ve teknik.',
        'Sevinçli ve kutlayıcı.',
        'Korkmuş ve kararsız.',
      ],
      optionsEn: <String>[
        'Mildly reproachful and sarcastic.',
        'Completely neutral and technical.',
        'Joyful and celebratory.',
        'Afraid and uncertain.',
      ],
      correctOptionIndex: 0,
      evidenceTr: '“Yine” sözcüğü gecikmenin tekrarlandığını vurguluyor.',
      evidenceEn: '“Again” emphasizes that the delay has happened repeatedly.',
      explanationTr: 'Teşekkür kalıbı burada gerçek övgü değil; tekrar eden gecikmeye yönelik sitem taşıyor.',
      explanationEn: 'The thanks are not literal praise; “again” signals frustration about a repeated delay.',
    ),
    DetectiveCase(
      id: 'coffee_and_sleep',
      minimumStage: 7,
      sourceTr: 'Kafe gözlemi',
      sourceEn: 'Cafe observation',
      passageTr: 'Kafenin yoğun olduğu günlerde müşteriler daha az uyuduklarını bildirdi. Araştırma, kahvenin uyku süresini azalttığını ölçmedi.',
      passageEn: 'On busy cafe days, customers reported sleeping less. The study did not measure whether coffee reduced their sleep.',
      questionTr: 'Veriden hangi sonuç çıkarılabilir?',
      questionEn: 'Which conclusion follows from the data?',
      optionsTr: <String>[
        'Yoğun günlerle az uyku bildirimi birlikte görülmüş; neden-sonuç kanıtlanmamış.',
        'Kahvenin az uykuya kesin olarak yol açtığı.',
        'Az uyuyan herkesin kafeye gittiği.',
        'Kafenin yoğunluğunun uyku süresini ölçtüğü.',
      ],
      optionsEn: <String>[
        'Busy days coincided with reports of less sleep; causation was not established.',
        'Coffee definitely caused the reduced sleep.',
        'Everyone who slept less visited the cafe.',
        'Cafe traffic measured each person’s sleep.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Araştırma, kahvenin uykuya etkisini ölçmediğini söylüyor.',
      evidenceEn: 'The study says it did not measure coffee’s effect on sleep.',
      explanationTr: 'Birlikte değişim, tek başına nedensellik göstermez; başka etkenler olabilir.',
      explanationEn: 'Co-occurrence alone does not show causation; other factors may explain it.',
    ),
    DetectiveCase(
      id: 'five_volunteers',
      minimumStage: 7,
      sourceTr: 'Ürün denemesi',
      sourceEn: 'Product trial',
      passageTr: 'Yeni uygulamayı gönüllü beş çalışan denedi; dördü beğendi. Denemeye katılmayan çalışanlardan görüş alınmadı.',
      passageEn: 'Five volunteers tried the new app; four liked it. Employees who did not volunteer were not asked.',
      questionTr: 'Yönetici için en güvenli yorum hangisidir?',
      questionEn: 'Which is the safest interpretation for the manager?',
      optionsTr: <String>[
        'Küçük gönüllü grupta dört kişi uygulamayı beğenmiş.',
        'Şirketteki çalışanların yüzde 80’i uygulamayı beğeniyor.',
        'Uygulamayı kullanmayanlar kesinlikle beğenmeyecek.',
        'Uygulama verimliliği artırdı.',
      ],
      optionsEn: <String>[
        'Four people in a small volunteer group liked the app.',
        'Eighty percent of all employees like the app.',
        'People who did not try it will dislike it.',
        'The app increased productivity.',
      ],
      correctOptionIndex: 0,
      evidenceTr:
          'Yalnızca beş gönüllünün görüşü toplanmış; verimlilik ölçülmemiş.',
      evidenceEn:
          'Only five volunteers were surveyed; productivity was not measured.',
      explanationTr:
          'Gönüllü küçük örneklem, tüm çalışanları temsil etmeyebilir.',
      explanationEn:
          'A small volunteer sample may not represent all employees.',
    ),
    DetectiveCase(
      id: 'may_reduce_costs',
      minimumStage: 7,
      sourceTr: 'Analist notu',
      sourceEn: 'Analyst memo',
      passageTr: 'Analist, trenler dolu çalışırsa yeni hattın maliyetleri azaltabileceğini yazdı. Yolcu sayısı henüz tahmin edilmedi.',
      passageEn: 'The analyst wrote that the new line may reduce costs if trains run full. Ridership has not yet been estimated.',
      questionTr: 'Analistin iddiasındaki kesinlik düzeyi nedir?',
      questionEn: 'How certain is the analyst’s claim?',
      optionsTr: <String>[
        'Koşula bağlı ve olasılık bildiren bir tahmin.',
        'Maliyetlerin kesin düşeceğini kanıtlayan ölçüm.',
        'Trenlerin zaten dolu çalıştığını gösteren gözlem.',
        'Yolcu sayısının bilindiğini belirten sonuç.',
      ],
      optionsEn: <String>[
        'A conditional prediction that expresses possibility.',
        'A measurement proving costs will definitely fall.',
        'An observation that trains are already full.',
        'A result stating that ridership is known.',
      ],
      correctOptionIndex: 0,
      evidenceTr:
          '“Azaltabilir” ve “eğer” koşul bildiriyor; yolcu sayısı bilinmiyor.',
      evidenceEn:
          '“May” and “if” express a condition, and ridership is unknown.',
      explanationTr: 'Koşullu dil, kesin sonuç değil; belirli şartlara bağlı olasılık anlatır.',
      explanationEn: 'Conditional wording describes a possibility, not a confirmed outcome.',
    ),
    DetectiveCase(
      id: 'complaint_counts',
      minimumStage: 7,
      sourceTr: 'Şube karşılaştırması',
      sourceEn: 'Branch comparison',
      passageTr: 'A şubesi 20, B şubesi 15 şikâyet aldı. A’nın 2.000, B’nin 400 müşterisi olduğu raporda ayrıca yazıyor.',
      passageEn: 'Branch A received 20 complaints and Branch B received 15. The report also lists 2,000 customers at A and 400 at B.',
      questionTr: 'Ham sayılar neden tek başına adil karşılaştırma sağlamaz?',
      questionEn: 'Why are the raw counts not a fair comparison by themselves?',
      optionsTr: <String>[
        'Şube büyüklükleri farklı; müşteri başına oran gerekir.',
        'A şubesindeki her şikâyetin geçersiz olduğu için.',
        'B şubesinin hiç sorunu olmadığı için.',
        'Şikâyet sayısı hiçbir zaman ölçülemediği için.',
      ],
      optionsEn: <String>[
        'The branches differ in size, so a per-customer rate is needed.',
        'Every complaint at A is invalid.',
        'Branch B has no problems.',
        'Complaint counts can never be measured.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'A’nın müşteri sayısı B’den beş kat fazla.',
      evidenceEn: 'Branch A serves five times as many customers as Branch B.',
      explanationTr: 'Mutlak sayı yerine payda dikkate alınmalı; oranlar karşılaştırmayı anlamlı kılar.',
      explanationEn: 'The denominator matters; rates make the comparison more informative.',
    ),
    DetectiveCase(
      id: 'leading_question',
      minimumStage: 7,
      sourceTr: 'Anket formu',
      sourceEn: 'Survey form',
      passageTr: 'Anket “Yeni parkın harika düzenini ne kadar beğendiniz?” diye soruyor. Katılımcılara düzeni beğenip beğenmedikleri sorulmuyor.',
      passageEn: 'A survey asks, “How much did you enjoy the park’s excellent new layout?” It never asks whether respondents liked it.',
      questionTr: 'Bu soru yanıtları nasıl etkileyebilir?',
      questionEn: 'How could this question affect responses?',
      optionsTr: <String>[
        'Olumlu görüş varsayıp yanıtı o yöne itebilir.',
        'Katılımcıların parkı görmesini sağlar.',
        'Örneklem sayısını kendiliğinden artırır.',
        'Düzenin maliyetini ölçer.',
      ],
      optionsEn: <String>[
        'It presumes a positive view and may steer answers that way.',
        'It ensures every respondent has visited the park.',
        'It automatically increases the sample size.',
        'It measures the layout’s cost.',
      ],
      correctOptionIndex: 0,
      evidenceTr: '“Harika” sözcüğü ve “ne kadar” kalıbı olumlu değerlendirmeyi peşinen kabul ediyor.',
      evidenceEn: '“Excellent” and “how much” presuppose a favorable opinion.',
      explanationTr: 'Yönlendirici ifade, tarafsız yanıt alanını daraltıp olumlu cevabı teşvik edebilir.',
      explanationEn: 'Leading wording can narrow the response and encourage a positive answer.',
    ),
    DetectiveCase(
      id: 'marathon_completers',
      minimumStage: 10,
      sourceTr: 'Koşu raporu',
      sourceEn: 'Race report',
      passageTr: 'Program raporu yalnızca maratonu tamamlayanlarla görüştü. Yarıştan çekilenler ve başlayamayanlar örnekleme alınmadı.',
      passageEn: 'A program report interviewed only people who finished the marathon. Those who withdrew or never started were excluded.',
      questionTr: 'Raporun en önemli yöntem sınırlılığı nedir?',
      questionEn:
          'What is the report’s most important methodological limitation?',
      optionsTr: <String>[
        'Yalnızca tamamlayanları seçerek başarıyı olduğundan yaygın gösterebilir.',
        'Görüşmeler katılımcıların deneyimini içeriyor.',
        'Maraton mesafesi sabit bir ölçüdür.',
        'Her katılımcının aynı parkurda koşması.',
      ],
      optionsEn: <String>[
        'Selecting only finishers may make success appear more common than it is.',
        'The interviews include participants’ experiences.',
        'A marathon has a fixed distance.',
        'Every participant ran the same course.',
      ],
      correctOptionIndex: 0,
      evidenceTr:
          'Programı bırakmış ya da başlayamamış kişiler dışarıda bırakılmış.',
      evidenceEn: 'People who withdrew or could not start were left out.',
      explanationTr: 'Yalnızca başarılı sonuçları görmek, başarısız ya da tamamlanmamış denemeleri gizler.',
      explanationEn: 'Looking only at successful outcomes hides unsuccessful or incomplete attempts.',
    ),
    DetectiveCase(
      id: 'sponsor_disclosure',
      minimumStage: 10,
      sourceTr: 'Araştırma özeti',
      sourceEn: 'Research summary',
      passageTr: 'Rapor yeni filtrenin suyu temizlediğini söylüyor. Çalışmanın üretici tarafından finanse edildiği dipnotta belirtilmiş; bağımsız tekrar yapılmamış.',
      passageEn: 'A report says the new filter cleans water. A footnote says the manufacturer funded the study, and no independent replication has been done.',
      questionTr: 'Bu bilgi karşısında en dengeli yaklaşım hangisidir?',
      questionEn: 'What is the most balanced response to this information?',
      optionsTr: <String>[
        'Bulguyu çıkar çatışmasını dikkate alarak değerlendirip bağımsız doğrulama aramak.',
        'Sponsor olduğu için sonucu otomatik olarak yanlış saymak.',
        'Raporu kesin kanıt kabul edip dipnotu yok saymak.',
        'Ürünün hiçbir koşulda çalışamayacağını ileri sürmek.',
      ],
      optionsEn: <String>[
        'Consider the funding and seek independent verification.',
        'Treat the finding as automatically false because of the sponsor.',
        'Accept it as conclusive and ignore the footnote.',
        'Claim the product cannot work under any conditions.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Finansman kaynağı açıklanmış; bağımsız tekrar bulunmuyor.',
      evidenceEn: 'The funding source is disclosed, but no independent replication exists.',
      explanationTr: 'Finansman tek başına sonucu çürütmez; şeffaflık ve bağımsız tekrar güveni güçlendirir.',
      explanationEn: 'Funding alone does not disprove a result; transparency and replication improve confidence.',
    ),
    DetectiveCase(
      id: 'average_wait',
      minimumStage: 10,
      sourceTr: 'Ulaşım özeti',
      sourceEn: 'Transit summary',
      passageTr: 'Yeni çizelgeden sonra ortalama bekleme süresi azaldı. Rapor, tek tek yolcuların ne kadar beklediğini veya medyanı vermiyor.',
      passageEn: 'Average waiting time fell after the new timetable. The report gives neither individual waits nor the median.',
      questionTr: 'Hangi iddia bu verinin ötesine geçer?',
      questionEn: 'Which claim goes beyond the available data?',
      optionsTr: <String>[
        'Her yolcunun artık daha kısa beklediği.',
        'Ortalama beklemenin raporda azaldığı.',
        'Bireysel sürelerin açıklanmadığı.',
        'Medyan değerin raporda bulunmadığı.',
      ],
      optionsEn: <String>[
        'Every passenger now waits less.',
        'The reported average wait decreased.',
        'Individual waits were not provided.',
        'The report does not include a median.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Yalnızca ortalama verilmiş; bireysel değişim açıklanmamış.',
      evidenceEn:
          'Only the average is given; individual changes are not described.',
      explanationTr: 'Ortalamanın düşmesi, her kişinin bekleme süresinin düştüğünü göstermez.',
      explanationEn:
          'A lower average does not mean every individual waited less.',
    ),
    DetectiveCase(
      id: 'rare_alert',
      minimumStage: 10,
      sourceTr: 'Tarama aracı',
      sourceEn: 'Screening tool',
      passageTr: 'Bir tarama aracı hastalığı olanların yüzde 80’ini işaretliyor. Hastalık toplumda çok nadir; yanlış alarm oranı da sıfır değil.',
      passageEn: 'A screening tool flags 80% of people who have a condition. The condition is rare, and the false-alarm rate is not zero.',
      questionTr: 'Pozitif sonuç için hangi yorum doğrudur?',
      questionEn: 'Which interpretation of a positive result is sound?',
      optionsTr: <String>[
        'Yüzde 80 duyarlılık, pozitif kişinin hasta olma olasılığının yüzde 80 olduğu anlamına gelmez.',
        'Pozitif çıkan herkes kesin hastadır.',
        'Hastalık nadir olduğu için araç kimseyi işaretleyemez.',
        'Duyarlılık ve hastalık yaygınlığı aynı ölçüdür.',
      ],
      optionsEn: <String>[
        '80% sensitivity does not mean an 80% chance that a positive person has the condition.',
        'Everyone who tests positive definitely has the condition.',
        'Because the condition is rare, the tool cannot flag anyone.',
        'Sensitivity and prevalence are the same measure.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Hastalık nadir ve yanlış alarm olasılığı sıfır değil.',
      evidenceEn: 'The condition is rare and false alarms can occur.',
      explanationTr: 'Pozitif sonucun anlamı taban oranına ve yanlış alarm oranına da bağlıdır.',
      explanationEn: 'The meaning of a positive result also depends on prevalence and false alarms.',
    ),
    DetectiveCase(
      id: 'either_ban_or_chaos',
      minimumStage: 10,
      sourceTr: 'Kurul konuşması',
      sourceEn: 'Board statement',
      passageTr: '“Ya bütün telefonları yasaklarız ya da hiçbir öğrenci odaklanamaz.” Konuşmacı başka bir kural seçeneğini tartışmıyor.',
      passageEn: '“Either we ban every phone or no student will focus.” The speaker does not discuss any other policy option.',
      questionTr: 'Akıl yürütmedeki sorun nedir?',
      questionEn: 'What is the reasoning problem?',
      optionsTr: <String>[
        'İki uç seçenek varmış gibi sunup ara çözümleri dışlıyor.',
        'Telefonların odaklanmayı etkileyebileceğini kabul ediyor.',
        'Bir kuralın uygulanma maliyetini hesaplıyor.',
        'Öğrencilerden doğrudan veri topluyor.',
      ],
      optionsEn: <String>[
        'It presents two extremes and excludes possible middle options.',
        'It acknowledges that phones may affect focus.',
        'It calculates the cost of enforcing a rule.',
        'It directly surveys students.',
      ],
      correctOptionIndex: 0,
      evidenceTr: 'Yalnızca tam yasak ve hiç odaklanamama karşıtlığı kurulmuş.',
      evidenceEn: 'Only a total ban and no focus are presented as choices.',
      explanationTr: 'Kısmi sınırlama gibi seçenekler değerlendirilmediğinden ikilem yapay biçimde daraltılmış.',
      explanationEn: 'Options such as limited use are ignored, creating an artificially narrow choice.',
    ),
  ];

  static const List<List<int>> _campaignIndexes = <List<int>>[
    <int>[0, 1, 2, 3],
    <int>[1, 2, 3, 4],
    <int>[0, 2, 3, 4],
    <int>[5, 6, 7, 8],
    <int>[6, 7, 8, 9],
    <int>[5, 7, 8, 9],
    <int>[10, 11, 12, 13],
    <int>[11, 12, 13, 14],
    <int>[10, 12, 13, 14],
    <int>[10, 11, 13, 14],
    <int>[6, 8, 10, 15],
    <int>[7, 9, 11, 16],
    <int>[8, 10, 12, 17],
    <int>[9, 11, 13, 18],
    <int>[5, 12, 14, 19],
    <int>[6, 10, 14, 15],
    <int>[15, 16, 17, 18],
    <int>[16, 17, 18, 19],
    <int>[15, 17, 18, 19],
    <int>[15, 16, 18, 19],
  ];

  static const List<int> _tierStarts = <int>[0, 5, 10, 15];
  static const int _casesPerTier = 5;

  final int stage;
  final List<DetectiveBoardCase> cases;
  final bool isPractice;
  final int round;

  String get boardSignature {
    final List<String> ids =
        cases.map((DetectiveBoardCase item) => item.caseFile.id).toList()
          ..sort();
    return ids.join('|');
  }

  static LanguageDetectiveScenario forCampaignLevel(
    int level, {
    bool english = false,
  }) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    return _build(
      indices: _campaignIndexes[level - 1],
      stage: level,
      english: english,
      isPractice: false,
      round: level,
      seed: ContentSeed.forLevel(
        gameId: 'language_detective:campaign',
        level: level,
      ),
    );
  }

  static LanguageDetectiveScenario forPracticeRound(
    int round, {
    bool english = false,
  }) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    int code = round - 1;
    final List<int> indices = <int>[];
    for (final int start in _tierStarts) {
      indices.add(start + code % _casesPerTier);
      code ~/= _casesPerTier;
    }
    return _build(
      indices: indices,
      stage: ((round - 1) % campaignLevels) + 1,
      english: english,
      isPractice: true,
      round: round,
      seed: ContentSeed.forLevel(
        gameId: 'language_detective:practice',
        level: round,
      ),
    );
  }

  static LanguageDetectiveScenario _build({
    required List<int> indices,
    required int stage,
    required bool english,
    required bool isPractice,
    required int round,
    required int seed,
  }) {
    final math.Random random = math.Random(seed);
    final List<int> caseOrder = List<int>.from(indices)..shuffle(random);
    final List<DetectiveBoardCase> cards = <DetectiveBoardCase>[];
    for (int boardIndex = 0; boardIndex < caseOrder.length; boardIndex++) {
      final DetectiveCase item = _bank[caseOrder[boardIndex]];
      if (item.optionsTr.length != 4 || item.optionsEn.length != 4) {
        throw StateError('A detective case needs four answers: ${item.id}');
      }
      if (item.optionsTr.toSet().length != 4 ||
          item.optionsEn.toSet().length != 4 ||
          item.correctOptionIndex < 0 ||
          item.correctOptionIndex > 3) {
        throw StateError('Invalid answer set in detective case ${item.id}');
      }
      final List<int> optionOrder = <int>[0, 1, 2, 3]..shuffle(random);
      cards.add(
        DetectiveBoardCase(
          caseFile: item,
          optionOrder: List<int>.unmodifiable(optionOrder),
        ),
      );
    }
    return LanguageDetectiveScenario(
      stage: stage,
      cases: List<DetectiveBoardCase>.unmodifiable(cards),
      isPractice: isPractice,
      round: round,
    );
  }
}
