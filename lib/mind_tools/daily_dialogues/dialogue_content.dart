class DialogueOption {
  const DialogueOption({
    required this.replyTr,
    required this.replyEn,
    required this.responseTr,
    required this.responseEn,
    required this.coachingTr,
    required this.coachingEn,
    required this.nextStepId,
    required this.clarityPoints,
  });

  final String replyTr;
  final String replyEn;
  final String responseTr;
  final String responseEn;
  final String coachingTr;
  final String coachingEn;
  final String nextStepId;
  final int clarityPoints;

  String reply(bool english) => english ? replyEn : replyTr;
  String response(bool english) => english ? responseEn : responseTr;
  String coaching(bool english) => english ? coachingEn : coachingTr;
}

class DialogueStep {
  const DialogueStep({
    required this.id,
    required this.otherPersonTr,
    required this.otherPersonEn,
    required this.promptTr,
    required this.promptEn,
    required this.options,
    this.endingTr,
    this.endingEn,
  });

  final String id;
  final String otherPersonTr;
  final String otherPersonEn;
  final String promptTr;
  final String promptEn;
  final List<DialogueOption> options;
  final String? endingTr;
  final String? endingEn;

  bool get isEnding => options.isEmpty;
  String otherPerson(bool english) => english ? otherPersonEn : otherPersonTr;
  String prompt(bool english) => english ? promptEn : promptTr;
  String ending(bool english) => (english ? endingEn : endingTr) ?? '';
}

class DialogueScenario {
  const DialogueScenario({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.categoryTr,
    required this.categoryEn,
    required this.settingTr,
    required this.settingEn,
    required this.startStepId,
    required this.steps,
  });

  final String id;
  final String titleTr;
  final String titleEn;
  final String categoryTr;
  final String categoryEn;
  final String settingTr;
  final String settingEn;
  final String startStepId;
  final Map<String, DialogueStep> steps;

  String title(bool english) => english ? titleEn : titleTr;
  String category(bool english) => english ? categoryEn : categoryTr;
  String setting(bool english) => english ? settingEn : settingTr;
  DialogueStep get start => steps[startStepId]!;
}

abstract final class DailyDialogueLibrary {
  static const List<DialogueScenario> scenarios = <DialogueScenario>[
    DialogueScenario(
      id: 'cafe_allergy',
      titleTr: 'Kafede açık sipariş',
      titleEn: 'A clear café order',
      categoryTr: 'KAFE · NET İLETİŞİM',
      categoryEn: 'CAFÉ · CLEAR COMMUNICATION',
      settingTr: 'İçerik hassasiyetini nazikçe belirt; gerekirse hazırlama koşulunu doğrula.',
      settingEn: 'State an ingredient sensitivity politely and clarify preparation when needed.',
      startStepId: 'opening',
      steps: <String, DialogueStep>{
        'opening': DialogueStep(
          id: 'opening',
          otherPersonTr: 'Merhaba, ne sipariş etmek istersiniz?',
          otherPersonEn: 'Hi there. What would you like to order?',
          promptTr: 'Yer fıstığına hassasiyetin var. Nasıl sipariş verirsin?',
          promptEn:
              'You have a peanut sensitivity. How would you place your order?',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Mercimek çorbası rica ederim. Yer fıstığına alerjim var; içerik ve hazırlama koşulunu kontrol edebilir misiniz?',
              replyEn: 'Lentil soup, please. I have a peanut allergy; could you check the ingredients and preparation?',
              responseTr:
                  'Elbette. Mutfağa içerik ve çapraz temas konusunda sorayım.',
              responseEn: 'Of course. I’ll check the ingredients and possible cross-contact with the kitchen.',
              coachingTr:
                  'İstek, önemli kısıt ve doğrulama talebi tek yanıtta açık.',
              coachingEn: 'The order, important constraint and request to verify are all clear.',
              nextStepId: 'confirm',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Şundan alayım. İçinde ne var?',
              replyEn: 'I’ll have that one. What is in it?',
              responseTr:
                  'Hangi malzemeyi özellikle kontrol etmemi istersiniz?',
              responseEn:
                  'Is there a particular ingredient you’d like me to check?',
              coachingTr: 'Soruyu daraltmak karşı tarafa hangi riski kontrol edeceğini söyler.',
              coachingEn: 'Narrowing the question tells the other person which risk to check.',
              nextStepId: 'clarify',
              clarityPoints: 0,
            ),
          ],
        ),
        'confirm': DialogueStep(
          id: 'confirm',
          otherPersonTr: 'Çorbada yer fıstığı yok; ancak mutfakta ortak ekipman kullanılıyor olabilir.',
          otherPersonEn: 'The soup has no peanuts, though the kitchen may use shared equipment.',
          promptTr: 'Bu bilgiye göre en yararlı devam hangisi?',
          promptEn:
              'Given that information, what is the most useful next reply?',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Bilgi için teşekkürler. Çapraz temas riskini de kontrol edip bana söyler misiniz?',
              replyEn: 'Thanks for checking. Could you also confirm whether there is a cross-contact risk?',
              responseTr: 'Kontrol ettim; güvenli olduğundan emin olamadığımız için başka bir seçenek önereyim.',
              responseEn: 'I checked; since we can’t confirm it is safe, let me suggest another option.',
              coachingTr: 'Teşekkür edip belirsiz kalan güvenlik bilgisini açıkça soruyorsun.',
              coachingEn: 'You thank them and directly clarify the remaining safety uncertainty.',
              nextStepId: 'end_clear',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Sorun değil, hazırlayın.',
              replyEn: 'That’s fine; please prepare it.',
              responseTr: 'Talebinizi mutfağa ileteceğim, ama bu riski doğrulayamıyorum.',
              responseEn: 'I can pass the request to the kitchen, but I can’t verify that risk.',
              coachingTr: 'Bilinmeyen bir riski varsaymak yerine doğrulanabilir seçeneği bekle.',
              coachingEn: 'Do not assume an unknown risk away; wait for a verifiable option.',
              nextStepId: 'end_partial',
              clarityPoints: 0,
            ),
          ],
        ),
        'clarify': DialogueStep(
          id: 'clarify',
          otherPersonTr: 'Tabii, hangi içerik senin için önemli?',
          otherPersonEn: 'Of course. Which ingredient matters for your order?',
          promptTr: 'Soruyu yararlı ve saygılı biçimde netleştir.',
          promptEn: 'Make the request specific and respectful.',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Yer fıstığına alerjim var. İçerik listesini ve ortak ekipman kullanılıp kullanılmadığını öğrenebilir misiniz?',
              replyEn: 'I have a peanut allergy. Could you check the ingredient list and whether shared equipment is used?',
              responseTr: 'Anladım; iki noktayı da mutfakla doğrulayayım.',
              responseEn:
                  'Understood. I’ll confirm both points with the kitchen.',
              coachingTr:
                  'Belirli bilgiyi söyleyip gereken iki kontrolü adlandırdın.',
              coachingEn: 'You identified the specific ingredient and both relevant checks.',
              nextStepId: 'end_clear',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Bende bir hassasiyet var, siz dikkat edersiniz.',
              replyEn: 'I have a sensitivity; you’ll know what to do.',
              responseTr: 'Hangi malzemeyi özellikle dışarıda tutmam gerektiğini bilmiyorum.',
              responseEn:
                  'I’m not sure which ingredient I should avoid for you.',
              coachingTr: 'Karşı tarafın ihtiyacını tahmin etmesini bekleme; önemli bilgiyi kendin ver.',
              coachingEn: 'Do not make the other person guess; provide the important detail.',
              nextStepId: 'end_partial',
              clarityPoints: 0,
            ),
          ],
        ),
        'end_clear': DialogueStep(
          id: 'end_clear',
          otherPersonTr: 'Sipariş netleşti; çalışan doğrulayamadığı durumda güvenli bir alternatif sundu.',
          otherPersonEn: 'The request is clear, and staff offered a safer alternative when they could not verify the risk.',
          promptTr: '',
          promptEn: '',
          options: <DialogueOption>[],
          endingTr: 'Açık bilgi, nazik ton ve doğrulama isteği konuşmayı güvenli bir sonuca taşıdı.',
          endingEn: 'Specific information, a respectful tone and a verification request led to a safer outcome.',
        ),
        'end_partial': DialogueStep(
          id: 'end_partial',
          otherPersonTr: 'Çalışan hangi içerikten kaçınılacağını veya hangi koşulun güvenli olduğunu doğrulayamadı.',
          otherPersonEn: 'Staff could not confirm which ingredient to avoid or whether the preparation was safe.',
          promptTr: '',
          promptEn: '',
          options: <DialogueOption>[],
          endingTr: 'Bir kez daha dene: hassasiyeti adlandır ve belirsizliği açıkça doğrulat.',
          endingEn: 'Try again: name the sensitivity and ask directly about the unresolved uncertainty.',
        ),
      },
    ),
    DialogueScenario(
      id: 'station_directions',
      titleTr: 'İstasyona yol tarifi',
      titleEn: 'Directions to the station',
      categoryTr: 'YOL TARİFİ · TAKİP SORUSU',
      categoryEn: 'DIRECTIONS · FOLLOW-UP',
      settingTr: 'Başlangıç noktanı söyle; durak, süre veya erişilebilirlik ayrıntısını doğrula.',
      settingEn: 'Name your starting point and confirm a stop, duration or accessibility detail.',
      startStepId: 'opening',
      steps: <String, DialogueStep>{
        'opening': DialogueStep(
          id: 'opening',
          otherPersonTr:
              'Merkez istasyonuna gitmek için hangi tarafa gidiyorsunuz?',
          otherPersonEn: 'Which way are you heading to reach Central Station?',
          promptTr: 'Meydandan yola çıkıyorsun ve toplu taşımayı kullanmak istiyorsun.',
          promptEn: 'You are starting from the square and want to use public transport.',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Kent Meydanı’ndan istasyona gideceğim. Hangi hatta binip nerede inmeliyim?',
              replyEn: 'I’m going from City Square to the station. Which line should I take and where should I get off?',
              responseTr: 'Tramvay 3’e binip iki durak sonra Merkez’de inin.',
              responseEn: 'Take tram 3 and get off at Central after two stops.',
              coachingTr: 'Başlangıç ve hedefi verip uygulanabilir yön tarifini istedin.',
              coachingEn: 'You supplied both endpoints and asked for actionable directions.',
              nextStepId: 'confirm',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'İstasyona nasıl giderim?',
              replyEn: 'How do I get to the station?',
              responseTr: 'Şu an hangi kavşaktan başladığınızı söyler misiniz?',
              responseEn:
                  'Could you tell me which junction you are starting from?',
              coachingTr: 'Başlangıç noktasını eklemek aynı isimli durak karışıklığını önler.',
              coachingEn: 'Adding your starting point prevents confusion between similarly named stops.',
              nextStepId: 'clarify',
              clarityPoints: 0,
            ),
          ],
        ),
        'confirm': DialogueStep(
          id: 'confirm',
          otherPersonTr:
              'İki durak sonra Merkez’de inin; istasyon çıkışı sağ tarafta.',
          otherPersonEn: 'Get off at Central after two stops; the station exit is on your right.',
          promptTr: 'Yolun doğru olduğundan emin olmak için ne sorarsın?',
          promptEn: 'What could you ask to confirm you are on the right route?',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Merkez durağının istasyon çıkışı sağdaki büyük saatli kapı mı?',
              replyEn: 'Is the station exit at Central the large clock entrance on the right?',
              responseTr: 'Evet, büyük saati görünce doğru yerde olduğunuzu anlarsınız.',
              responseEn: 'Yes. The large clock is a good landmark that you are at the right place.',
              coachingTr: 'Gözle seçilebilen bir işaretle tarifi doğruladın.',
              coachingEn:
                  'You confirmed the route with an easy-to-see landmark.',
              nextStepId: 'end_clear',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Tamam, anladım.',
              replyEn: 'Okay, got it.',
              responseTr: 'Yardımcı olabildiysem ne mutlu.',
              responseEn: 'Glad I could help.',
              coachingTr:
                  'Tarif alınmış olsa da durak veya yön teyidi güven sağlar.',
              coachingEn:
                  'A quick stop or direction check can prevent a missed turn.',
              nextStepId: 'end_partial',
              clarityPoints: 1,
            ),
          ],
        ),
        'clarify': DialogueStep(
          id: 'clarify',
          otherPersonTr:
              'Elbette. Meydandaki belediye binasının önünde misiniz?',
          otherPersonEn: 'Sure. Are you outside the city hall on the square?',
          promptTr: 'Başlangıç yerini kısa ve belirgin biçimde yanıtla.',
          promptEn: 'Answer with a short, identifiable starting point.',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Evet, belediye binasının önündeyim. İstasyona tramvayla gitmek istiyorum.',
              replyEn: 'Yes, I’m outside city hall. I’d like to take the tram to the station.',
              responseTr: 'O hâlde Tramvay 3’e binip iki durak sonra inin.',
              responseEn:
                  'In that case, take tram 3 and get off after two stops.',
              coachingTr:
                  'Konum ve tercih edilen ulaşım biçimi cevabı özelleştirdi.',
              coachingEn: 'Your location and preferred transport made the directions specific.',
              nextStepId: 'end_clear',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Buradayım işte, siz tarif edin.',
              replyEn: 'I’m right here; just give me directions.',
              responseTr: 'Başlangıç yerini bilmeden doğru hattı seçemem.',
              responseEn: 'I can’t choose the right route without knowing your starting point.',
              coachingTr:
                  'Savunmaya geçmek yerine görünen bir yer işareti söyle.',
              coachingEn:
                  'Rather than sounding defensive, name a visible landmark.',
              nextStepId: 'end_partial',
              clarityPoints: 0,
            ),
          ],
        ),
        'end_clear': DialogueStep(
          id: 'end_clear',
          otherPersonTr: 'Hedef, başlangıç ve görünür durak işareti netleşti.',
          otherPersonEn: 'The destination, starting point and visible stop landmark are clear.',
          promptTr: '',
          promptEn: '',
          options: <DialogueOption>[],
          endingTr: 'Tarifi kendi hedef noktanla ilişkilendirip küçük bir teyit sorusu sordun.',
          endingEn: 'You connected the route to your own destination and checked one practical detail.',
        ),
        'end_partial': DialogueStep(
          id: 'end_partial',
          otherPersonTr:
              'Bir durak veya başlangıç ayrıntısı hâlâ teyit edilmedi.',
          otherPersonEn:
              'A stop or starting-point detail is still unconfirmed.',
          promptTr: '',
          promptEn: '',
          options: <DialogueOption>[],
          endingTr: 'Bir kez daha dene: başlangıç noktasını belirt ve görünür bir işaretle kontrol et.',
          endingEn: 'Try again: state your starting point and verify the route with a visible landmark.',
        ),
      },
    ),
    DialogueScenario(
      id: 'clinic_booking',
      titleTr: 'Randevu saatini ayarlama',
      titleEn: 'Booking an appointment',
      categoryTr: 'RANDEVU · TARİH VE TEYİT',
      categoryEn: 'APPOINTMENT · DATE AND CONFIRMATION',
      settingTr: 'Uygun zaman aralığını söyle; gün, saat ve teyit bilgisini tekrar et.',
      settingEn: 'Offer a time window and repeat the day, time and confirmation details.',
      startStepId: 'opening',
      steps: <String, DialogueStep>{
        'opening': DialogueStep(
          id: 'opening',
          otherPersonTr: 'Randevu için hangi gün ve saatler size uygun?',
          otherPersonEn: 'Which day and time would work for your appointment?',
          promptTr: 'Salı öğleden sonra uygunsun; net bir zaman aralığı ver.',
          promptEn: 'You are free Tuesday afternoon; give a clear time window.',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Salı 14.00–16.00 arasında uygunum. Bu aralıkta boş saatiniz var mı?',
              replyEn: 'I’m available Tuesday between 2 and 4 p.m. Do you have an open slot then?',
              responseTr: 'Salı saat 15.00 için bir boşluk görüyorum.',
              responseEn: 'I have an opening on Tuesday at 3 p.m.',
              coachingTr:
                  'Gün, zaman aralığı ve net müsaitlik sorusu aynı mesajda.',
              coachingEn: 'Your day, time window and request for an available slot are all explicit.',
              nextStepId: 'confirm',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Öğleden sonra olabilir.',
              replyEn: 'Some time in the afternoon might work.',
              responseTr: 'Hangi gün ve yaklaşık saat aralığı?',
              responseEn: 'Which day and approximate time window?',
              coachingTr: '“Öğleden sonra” farklı kişiler için farklı saatler demek olabilir.',
              coachingEn:
                  '“Afternoon” can mean different hours to different people.',
              nextStepId: 'clarify',
              clarityPoints: 0,
            ),
          ],
        ),
        'confirm': DialogueStep(
          id: 'confirm',
          otherPersonTr: 'Salı 15.00’te randevunuzu oluşturdum.',
          otherPersonEn: 'I have booked your appointment for Tuesday at 3 p.m.',
          promptTr: 'Yanlış anlaşılmayı önlemek için hangi adım yararlı?',
          promptEn: 'What would help prevent a misunderstanding?',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Salı 15.00, doğru mu? Adresi ve teyit numarasını da paylaşabilir misiniz?',
              replyEn: 'Tuesday at 3 p.m., correct? Could you also share the address and confirmation number?',
              responseTr:
                  'Evet. Adres ve teyit numarasını mesajla gönderiyorum.',
              responseEn: 'Correct. I’ll send the address and confirmation number by message.',
              coachingTr: 'Bilgiyi geri okuyup randevu için gereken sonraki adımları sordun.',
              coachingEn: 'You repeated the booking details and requested practical follow-up information.',
              nextStepId: 'end_clear',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Tamam, görüşürüz.',
              replyEn: 'Okay, see you then.',
              responseTr: 'Güzel günler.',
              responseEn: 'Have a good day.',
              coachingTr:
                  'Saati geri okumak tarih ve saat karışıklığını azaltır.',
              coachingEn: 'Repeating the time reduces date and time mix-ups.',
              nextStepId: 'end_partial',
              clarityPoints: 1,
            ),
          ],
        ),
        'clarify': DialogueStep(
          id: 'clarify',
          otherPersonTr:
              'Salı mı, çarşamba mı? Saat aralığını da öğrenebilir miyim?',
          otherPersonEn:
              'Tuesday or Wednesday? Could I also get a time window?',
          promptTr: 'Belirsizliği azaltan açık bir yanıt ver.',
          promptEn: 'Give a clear answer that removes the ambiguity.',
          options: <DialogueOption>[
            DialogueOption(
              replyTr:
                  'Salı günü 14.00’ten sonra uygunum; 15.00 benim için uygun.',
              replyEn: 'Tuesday after 2 p.m. works for me; 3 p.m. is suitable.',
              responseTr: 'Salı 15.00 için kaydınızı oluşturdum.',
              responseEn: 'I have booked you for Tuesday at 3 p.m.',
              coachingTr:
                  'Günü ve saati kesinleştirince randevu oluşturulabilir.',
              coachingEn: 'Once the day and time are specific, the appointment can be confirmed.',
              nextStepId: 'end_clear',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Fark etmez, uygun bir saate yazın.',
              replyEn: 'Either is fine; just choose a suitable time.',
              responseTr: 'Takvimde size uyan bir saati doğrulayamıyorum.',
              responseEn: 'I can’t confirm a time that works for you without a preference.',
              coachingTr: 'Uygun olmadığın zamanları belirtmek karşı tarafın doğru seçim yapmasına yardım eder.',
              coachingEn: 'Saying when you are unavailable helps the other person choose accurately.',
              nextStepId: 'end_partial',
              clarityPoints: 0,
            ),
          ],
        ),
        'end_clear': DialogueStep(
          id: 'end_clear',
          otherPersonTr: 'Gün ve saat karşılıklı tekrarlandı; adres ve teyit bilgisi de istendi.',
          otherPersonEn: 'The day and time were repeated, and the address and confirmation details were requested.',
          promptTr: '',
          promptEn: '',
          options: <DialogueOption>[],
          endingTr:
              'Kısa bir teyit ve net sonraki adım, randevuyu güvenceye aldı.',
          endingEn: 'A brief read-back and clear next step made the booking reliable.',
        ),
        'end_partial': DialogueStep(
          id: 'end_partial',
          otherPersonTr:
              'Randevu saati söylenmiş olsa da ayrıntı tekrar edilmedi.',
          otherPersonEn:
              'A time was offered, but the detail was not repeated back.',
          promptTr: '',
          promptEn: '',
          options: <DialogueOption>[],
          endingTr: 'Bir kez daha dene: tarihi ve saati geri oku, gerekli teyit bilgisini iste.',
          endingEn: 'Try again: repeat the date and time and ask for the confirmation details you need.',
        ),
      },
    ),
    DialogueScenario(
      id: 'work_deadline',
      titleTr: 'İş teslimini netleştirme',
      titleEn: 'Clarifying a work handoff',
      categoryTr: 'İŞ İLETİŞİMİ · KAPSAM',
      categoryEn: 'WORK · SCOPE AND DEADLINE',
      settingTr: 'Çıktıyı, teslim zamanını ve tamamlanma ölçütünü kısa sorularla netleştir.',
      settingEn: 'Use concise questions to clarify the deliverable, deadline and acceptance criteria.',
      startStepId: 'opening',
      steps: <String, DialogueStep>{
        'opening': DialogueStep(
          id: 'opening',
          otherPersonTr:
              'Bu özeti bugün mümkün olduğunda tamamlayabilir misin?',
          otherPersonEn: 'Could you finish this summary sometime today?',
          promptTr: 'İş yükünü planlamak için teslim ve kapsamı netleştir.',
          promptEn: 'Clarify scope and delivery time so you can plan the work.',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Elbette. Saat kaçta gerekli ve tek sayfalık özet mi, yoksa kaynak bağlantıları da olsun mu?',
              replyEn: 'Sure. What time do you need it, and should it be a one-page summary or include source links too?',
              responseTr: 'Saat 16.00’ya kadar; kısa özet ve üç temel kaynak bağlantısı yeterli.',
              responseEn: 'By 4 p.m.; a short summary and three key source links are enough.',
              coachingTr: 'Zamanı ve teslim biçimini birlikte sorarak yeniden iş yapmayı önledin.',
              coachingEn:
                  'Clarifying timing and format together helps avoid rework.',
              nextStepId: 'confirm',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Tamam, hallederim.',
              replyEn: 'Okay, I’ll take care of it.',
              responseTr: 'Teşekkürler. Gün bitmeden gönderirsen yeter.',
              responseEn:
                  'Thanks. Sending it before the end of the day is enough.',
              coachingTr:
                  '“Gün bitmeden” farklı teslim beklentileri oluşturabilir.',
              coachingEn: '“Before the end of the day” may create different expectations.',
              nextStepId: 'clarify',
              clarityPoints: 0,
            ),
          ],
        ),
        'confirm': DialogueStep(
          id: 'confirm',
          otherPersonTr:
              'Evet, 16.00’ya kadar bir sayfa ve üç kaynak bağlantısı.',
          otherPersonEn: 'Yes: one page and three source links by 4 p.m.',
          promptTr: 'Tamamlanma ölçütünü doğrula.',
          promptEn: 'Confirm how the finished work will be judged.',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Anladım: üç ana bulguyu bir sayfada özetleyip üç kaynağı ekleyeceğim; 16.00’da paylaşırım.',
              replyEn: 'Understood: I’ll summarize three key findings on one page, add three sources and share it at 4 p.m.',
              responseTr: 'Aynen böyle. Teşekkürler.',
              responseEn: 'Exactly. Thanks.',
              coachingTr: 'Kapsamı ve zamanı kendi sözlerinle geri okuyup mutabakatı kontrol ettin.',
              coachingEn:
                  'You restated scope and timing to check that you both agree.',
              nextStepId: 'end_clear',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Tamam, elimden geleni yaparım.',
              replyEn: 'Okay, I’ll do my best.',
              responseTr: 'Güzel. Ne beklediğimi konuştuğumuz gibi not ettim.',
              responseEn: 'Great. I’ve noted the deliverable we discussed.',
              coachingTr: 'Somut teslim ölçütünü kısaca tekrar etmek ortak beklentiyi sağlamlaştırır.',
              coachingEn: 'Repeating the concrete deliverable helps align expectations.',
              nextStepId: 'end_partial',
              clarityPoints: 1,
            ),
          ],
        ),
        'clarify': DialogueStep(
          id: 'clarify',
          otherPersonTr: 'En geç 17.00’de gerekli. Yönetim ekibine sunacağım; kaynak da önemli.',
          otherPersonEn: 'I need it by 5 p.m. for the management team, and sources matter.',
          promptTr: 'Kapsamı şimdi kibarca somutlaştır.',
          promptEn: 'Now make the scope concrete and professional.',
          options: <DialogueOption>[
            DialogueOption(
              replyTr: 'Anladım. Bir sayfalık kısa özet ve üç kaynak bağlantısı hazırlayıp 16.30’da paylaşsam uygun olur mu?',
              replyEn: 'Understood. Would a one-page summary with three source links at 4:30 p.m. work for you?',
              responseTr: 'Evet, 16.30 uygun; teşekkürler.',
              responseEn: 'Yes, 4:30 works. Thank you.',
              coachingTr:
                  'Sınırı dikkate alıp açık bir öneri sundun ve teyit aldın.',
              coachingEn: 'You respected the deadline and proposed a specific, confirmable handoff.',
              nextStepId: 'end_clear',
              clarityPoints: 2,
            ),
            DialogueOption(
              replyTr: 'Çok iş var; daha sonra gönderirim.',
              replyEn: 'There is a lot to do; I’ll send it later.',
              responseTr: 'Ne zaman geleceğini planlayamıyorum.',
              responseEn: 'I can’t plan around an unspecified time.',
              coachingTr: 'Gecikme riski varsa erken haber verip gerçekçi bir zaman öner.',
              coachingEn: 'If the deadline is at risk, raise it early and propose a realistic time.',
              nextStepId: 'end_partial',
              clarityPoints: 0,
            ),
          ],
        ),
        'end_clear': DialogueStep(
          id: 'end_clear',
          otherPersonTr:
              'Teslim biçimi ve zamanı karşılıklı olarak somutlaştı.',
          otherPersonEn: 'The format and handoff time are now concrete and mutually understood.',
          promptTr: '',
          promptEn: '',
          options: <DialogueOption>[],
          endingTr: 'Kapsamı, zamanı ve kabul ölçütünü netleştirmek işin sonradan yeniden yapılmasını azaltır.',
          endingEn: 'Clarifying scope, timing and acceptance criteria reduces avoidable rework.',
        ),
        'end_partial': DialogueStep(
          id: 'end_partial',
          otherPersonTr: 'Teslim beklentisinin bir bölümü hâlâ yoruma açık.',
          otherPersonEn: 'Part of the handoff expectation is still open to interpretation.',
          promptTr: '',
          promptEn: '',
          options: <DialogueOption>[],
          endingTr: 'Bir kez daha dene: somut bir teslim zamanı ve çıktının biçimini birlikte teyit et.',
          endingEn: 'Try again: confirm a specific delivery time and the expected format together.',
        ),
      },
    ),
  ];
}
