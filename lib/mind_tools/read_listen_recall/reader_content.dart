class RecallQuestion {
  const RecallQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.evidence,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String evidence;
}

class RecallArticle {
  const RecallArticle({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.categoryTr,
    required this.categoryEn,
    required this.bodyTr,
    required this.bodyEn,
    required this.questionsTr,
    required this.questionsEn,
    required this.wordTr,
    required this.wordEn,
    required this.meaningTr,
    required this.meaningEn,
    required this.exampleTr,
    required this.exampleEn,
  });

  final String id;
  final String titleTr;
  final String titleEn;
  final String categoryTr;
  final String categoryEn;
  final String bodyTr;
  final String bodyEn;
  final List<RecallQuestion> questionsTr;
  final List<RecallQuestion> questionsEn;
  final String wordTr;
  final String wordEn;
  final String meaningTr;
  final String meaningEn;
  final String exampleTr;
  final String exampleEn;

  String title(bool english) => english ? titleEn : titleTr;
  String category(bool english) => english ? categoryEn : categoryTr;
  String body(bool english) => english ? bodyEn : bodyTr;
  String word(bool english) => english ? wordEn : wordTr;
  String meaning(bool english) => english ? meaningEn : meaningTr;
  String example(bool english) => english ? exampleEn : exampleTr;
  List<RecallQuestion> questions(bool english) =>
      english ? questionsEn : questionsTr;
}

abstract final class RecallArticleLibrary {
  static const List<RecallArticle> articles = <RecallArticle>[
    RecallArticle(
      id: 'fog_lantern',
      titleTr: 'Sisli kıyıda üç ışık',
      titleEn: 'Three lights on a foggy shore',
      categoryTr: 'DİKKATLİ OKUMA',
      categoryEn: 'CAREFUL READING',
      bodyTr: 'Kıyı kasabasının fener sorumlusu Leyla, sisli gecelerde teknelere üç kısa ışık gönderirdi. Yeni görevli Cem, ışıkları görünce feneri daha hızlı çevirmeyi önerdi. Leyla önce kıyıdaki taş işaretlerini kontrol etti: fener aynı yerdeydi, fakat sis ışığın menzilini kısaltmıştı. Lambanın hızını artırmak, teknelerin hangi koyda olduğunu söylemiyordu. Bunun yerine ışık aralıklarını sabit tuttu ve kıyı telsizinden son güvenli konumu istedi. Tekne kaptanı, kuzeydeki küçük girintide olduğunu bildirdi. Leyla da o noktaya ait farklı bir ışık dizisi gönderdi. Tekne güvenli biçimde limana döndü. Cem ertesi sabah defterde iki sütun açtı: “görülen ışık” ve “doğrulanan konum.” Leyla ona, iyi bir gözlemin tek başına yeterli olmadığını; doğru karar için gözlemi bağımsız bir kayıtla karşılaştırmak gerektiğini anlattı.',
      bodyEn: 'On foggy nights, Leyla, the keeper of a coastal beacon, sent three short flashes to nearby boats. Cem, the new assistant, suggested turning the lamp faster as soon as he saw a vessel. Leyla first checked the stone markers on shore: the beacon had not moved, but fog had shortened the range of the light. Increasing the flash rate would not tell them which inlet held the boat. Instead, she kept the pattern steady and asked for its last safe position over the coast radio. The captain reported a small cove to the north. Leyla sent the distinct pattern assigned to that location, and the boat returned safely. The next morning Cem made two columns in the log: “light observed” and “position confirmed.” A useful observation, Leyla explained, is stronger when it is checked against an independent record.',
      questionsTr: <RecallQuestion>[
        RecallQuestion(
          prompt: 'Leyla neden ışığı hızlandırmadı?',
          options: <String>[
            'Sis menzili kısaltmıştı; hız teknenin yerini doğrulamıyordu.',
            'Lambanın pili bitmişti.',
            'Tekne ışığı göremiyordu.',
          ],
          correctIndex: 0,
          evidence: 'Metin, sisin ışık menzilini kısalttığını ve hızın koyu göstermeyeceğini söylüyor.',
        ),
        RecallQuestion(
          prompt: 'Cem deftere hangi iki sütunu ekledi?',
          options: <String>[
            'Hava durumu ve rüzgâr yönü',
            'Görülen ışık ve doğrulanan konum',
            'Tekne adı ve mürettebat sayısı',
          ],
          correctIndex: 1,
          evidence: 'Cem, gözlemi bağımsız konum bilgisiyle karşılaştırmak için iki kayıt tuttu.',
        ),
      ],
      questionsEn: <RecallQuestion>[
        RecallQuestion(
          prompt: 'Why did Leyla keep the flash pattern steady?',
          options: <String>[
            'The battery was almost empty.',
            'Fog shortened visibility; speed would not confirm the boat’s inlet.',
            'The boat could not see any light.',
          ],
          correctIndex: 1,
          evidence: 'Fog reduced the light’s range, while a faster flash could not identify the boat’s location.',
        ),
        RecallQuestion(
          prompt: 'What did Cem record in two columns?',
          options: <String>[
            'Weather and wind direction',
            'Observed light and confirmed position',
            'Boat name and crew size',
          ],
          correctIndex: 1,
          evidence: 'He compared the observation with an independent position record.',
        ),
      ],
      wordTr: 'menzil',
      wordEn: 'range',
      meaningTr: 'Bir şeyin ulaşabildiği uzaklık veya kapsam.',
      meaningEn: 'The distance or extent that something can reach.',
      exampleTr: 'Sis, fener ışığının menzilini azalttı.',
      exampleEn: 'The fog reduced the range of the beacon.',
    ),
    RecallArticle(
      id: 'market_route',
      titleTr: 'Pazarda küçük bir rota',
      titleEn: 'A small route through the market',
      categoryTr: 'PLANLAMA',
      categoryEn: 'PLANNING',
      bodyTr: 'Mina, cumartesi pazarına giderken alışveriş listesini ürün türlerine göre ayırdı. Soğukta bozulabilecek yoğurt ve peyniri listenin sonuna yazdı; önce dayanıklı sebzeleri ve kuru bakliyatı aldı. Pazarın girişinde kalabalık olunca doğrudan en yakın tezgâha yönelmek yerine, boşalan yan koridoru kullandı. Bir satıcı, kestirme yolun daha kısa olduğunu söyledi; Mina ise kasaların yoğunluğunu ve taşıdığı çantanın ağırlığını birlikte düşündü. Rotasını iki kez değiştirse de toplam yürüyüşü kısaldı ve soğuk ürünler daha az süre dışarıda kaldı. Evde listeye bakınca unuttuğu tek şeyin limon olduğunu fark etti. Mina, “iyi planlama hiç değişiklik yapmamak değil; yeni bilgiye göre sırayı güncellemek” diye not aldı.',
      bodyEn: 'Before going to the Saturday market, Mina grouped her shopping list by type. She left yoghurt and cheese, which spoil in warmth, until the end; first she bought durable vegetables and dried beans. When the entrance became crowded, she used a side aisle instead of heading to the nearest stall. A vendor pointed out a shorter shortcut, but Mina also considered the queues and the weight of her bags. She changed direction twice, yet walked less overall and kept the chilled goods out of the cold bag for less time. At home she noticed that the only item she had missed was a lemon. Good planning, she wrote, does not mean refusing to change a plan; it means updating the order when new information arrives.',
      questionsTr: <RecallQuestion>[
        RecallQuestion(
          prompt: 'Mina yoğurt ve peyniri neden sona bıraktı?',
          options: <String>[
            'Pazar kapanmak üzereydi.',
            'Sıcakta bozulabilecekleri için dışarıda kalma sürelerini azaltmak istedi.',
            'Bu ürünler listenin en altında yazıyordu.',
          ],
          correctIndex: 1,
          evidence: 'Soğuk ürünleri çantada daha kısa süre tutmayı hedefledi.',
        ),
        RecallQuestion(
          prompt: 'Mina’ya göre iyi planlama neydi?',
          options: <String>[
            'İlk belirlenen rotadan hiç sapmamak',
            'Yeni bilgiye göre sırayı güncellemek',
            'Her zaman en kısa koridoru seçmek',
          ],
          correctIndex: 1,
          evidence: 'Mina, kalabalık ve çanta ağırlığı gibi yeni bilgilere göre yön değiştirdi.',
        ),
      ],
      questionsEn: <RecallQuestion>[
        RecallQuestion(
          prompt: 'Why did Mina buy yoghurt and cheese last?',
          options: <String>[
            'The market was closing.',
            'They could spoil in warmth, so she wanted less time out of the cold bag.',
            'They were written last on the list.',
          ],
          correctIndex: 1,
          evidence: 'She was minimizing how long chilled goods stayed out.',
        ),
        RecallQuestion(
          prompt: 'What did Mina call good planning?',
          options: <String>[
            'Never changing the first route',
            'Updating the order when new information arrives',
            'Always taking the shortest aisle',
          ],
          correctIndex: 1,
          evidence: 'She adapted to crowding and bag weight rather than following a fixed route.',
        ),
      ],
      wordTr: 'dayanıklı',
      wordEn: 'durable',
      meaningTr: 'Kolay bozulmayan veya yıpranmayan.',
      meaningEn: 'Able to last without being easily damaged or spoiled.',
      exampleTr: 'Dayanıklı sebzeleri önce aldı.',
      exampleEn: 'She bought durable vegetables first.',
    ),
    RecallArticle(
      id: 'water_glass',
      titleTr: 'Bardağın üzerindeki damlalar',
      titleEn: 'The droplets on the glass',
      categoryTr: 'NEDEN–SONUÇ',
      categoryEn: 'CAUSE AND EFFECT',
      bodyTr: 'Sıcak bir öğleden sonra Arda, soğuk su bardağının dışında küçük damlalar gördü. İlk anda bardağın çatladığını düşündü. Ablası bardağı kurulayıp masaya koydu; birkaç dakika sonra yüzey yeniden ıslandı. Bardağın içindeki su taşmıyor, kapta da delik bulunmuyordu. Ablası, odadaki görünmez su buharının soğuk cama değince sıvı damlalara dönüştüğünü açıkladı. Arda aynı deneyi boş ve kuru bir kavanozla tekrarladı: kavanoz soğuyunca dış yüzeyinde yine damlalar oluştu. Böylece suyun camın içinden sızmadığını, havadaki nemin yüzeye tutunduğunu anladı. Ablası son olarak kavanozun ağzını kapattı; dış damlalar yine oluştu. Kapak, havayı camın dışından uzaklaştırmadığı için sonuç değişmemişti.',
      bodyEn: 'On a warm afternoon, Arda noticed tiny droplets on the outside of a glass of cold water. At first he thought the glass had cracked. His sister dried it and placed it on the table; a few minutes later the outside was wet again. The water had not spilled, and the glass had no hole. She explained that invisible water vapour in the room cooled against the cold surface and became liquid droplets. Arda repeated the observation with an empty, dry jar. Once it cooled, droplets appeared on the outside again. That showed the water was not leaking through the glass: moisture from the air had collected on the surface. His sister then closed the jar. The droplets still appeared because the lid did not remove the air surrounding the outside of the jar.',
      questionsTr: <RecallQuestion>[
        RecallQuestion(
          prompt: 'Damlalar nereden geldi?',
          options: <String>[
            'Bardaktaki su camdan sızdı.',
            'Havadaki su buharı soğuk yüzeyde sıvılaştı.',
            'Arda masaya su döktü.',
          ],
          correctIndex: 1,
          evidence: 'Kuru kavanozun dışında da, içi boşken damlalar oluştu.',
        ),
        RecallQuestion(
          prompt: 'Kavanozun kapağını kapatınca neden damlalar oluşmaya devam etti?',
          options: <String>[
            'Kapak oda havasını dış yüzeyden uzaklaştırmadı.',
            'Su kavanozdan taştı.',
            'Cam ısındı.',
          ],
          correctIndex: 0,
          evidence: 'Damlalar dış yüzeydeydi; kapak çevredeki havayı ortadan kaldırmıyordu.',
        ),
      ],
      questionsEn: <RecallQuestion>[
        RecallQuestion(
          prompt: 'Where did the droplets come from?',
          options: <String>[
            'Water leaked through the glass.',
            'Water vapour in the air condensed on the cold surface.',
            'Arda spilled water on the table.',
          ],
          correctIndex: 1,
          evidence: 'Droplets also formed on the outside of an empty, dry jar.',
        ),
        RecallQuestion(
          prompt: 'Why did droplets still form after the jar was closed?',
          options: <String>[
            'The lid did not remove the air around the outside.',
            'Water overflowed from the jar.',
            'The glass warmed up.',
          ],
          correctIndex: 0,
          evidence: 'The droplets formed outside; a lid does not remove the surrounding air.',
        ),
      ],
      wordTr: 'sıvılaşmak',
      wordEn: 'condense',
      meaningTr: 'Gaz hâlindeki maddenin sıvıya dönüşmesi.',
      meaningEn: 'To change from a gas into a liquid.',
      exampleTr: 'Su buharı soğuk yüzeyde sıvılaştı.',
      exampleEn: 'Water vapour condensed on the cold surface.',
    ),
    RecallArticle(
      id: 'quiet_interval',
      titleTr: 'Sessiz aralığın etkisi',
      titleEn: 'The effect of a quiet interval',
      categoryTr: 'DİKKAT VE HAFIZA',
      categoryEn: 'ATTENTION AND MEMORY',
      bodyTr: 'Ece, yeni bir kelimeyi çalışırken bildirim seslerini kapattı; ancak masasına daha fazla not koydu. İlk denemede aynı paragrafı dört kez okuduğu hâlde ana fikri hatırlayamadı. Sonraki gün, masada yalnızca tek bir kart bıraktı ve her iki dakikada bir durup metni kendi cümlesiyle anlattı. Çalışma süresi kısalmadı, ama tekrar sayısı azaldı. Ece bunun üzerine “sessizlik tek başına hafıza oluşturmaz; dikkatin bir hedefte kalmasına yardım eder” diye yazdı. Bir hafta sonra kartı kapatıp kelimeyi örnek cümlede hatırlamayı denedi. Kelimeyi hemen çıkaramadı; anlamı düşündü, cümleyi yeniden kurdu ve sonra doğru karşılığı buldu. Gecikmeli hatırlama daha yavaş olmuştu, fakat kelimeyi yalnızca yeniden okumaktan daha iyi aklında tuttu.',
      bodyEn: 'Ece silenced her notifications while studying a new word, but left more notes on the desk. During her first attempt, she read the same paragraph four times and still could not recall its main idea. The next day she kept one card on the desk and stopped every two minutes to explain the text in her own words. The study session was not shorter, but she reread less. She wrote: “Quiet alone does not create memory; it helps attention stay with one goal.” A week later she covered the card and tried to use the word in an example sentence. She could not produce it immediately, so she recalled its meaning, rebuilt the sentence and found the word. Retrieval was slower, but she remembered it better than when she had only reread it.',
      questionsTr: <RecallQuestion>[
        RecallQuestion(
          prompt: 'Ece ikinci çalışmada neyi değiştirdi?',
          options: <String>[
            'Çalışma süresini yarıya indirdi.',
            'Tek karta odaklanıp metni kendi cümleleriyle geri çağırdı.',
            'Bildirimleri açıp daha çok not aldı.',
          ],
          correctIndex: 1,
          evidence: 'Ece metni aralıklı olarak kendi sözleriyle anlattı ve yeniden okuma sayısı azaldı.',
        ),
        RecallQuestion(
          prompt: 'Bir hafta sonra kelimeyi nasıl hatırladı?',
          options: <String>[
            'Kartı tekrar tekrar okuyarak',
            'Anlamını çağırıp örnek cümleyi yeniden kurarak',
            'Bildirim sesini dinleyerek',
          ],
          correctIndex: 1,
          evidence: 'Gecikmeli hatırlamada anlamdan yola çıkıp cümleyi kurdu.',
        ),
      ],
      questionsEn: <RecallQuestion>[
        RecallQuestion(
          prompt: 'What changed in Ece’s second study session?',
          options: <String>[
            'She cut the session in half.',
            'She focused on one card and recalled the text in her own words.',
            'She enabled notifications and wrote more notes.',
          ],
          correctIndex: 1,
          evidence: 'She paused to explain the text herself and reread less.',
        ),
        RecallQuestion(
          prompt: 'How did she recall the word a week later?',
          options: <String>[
            'By reading the card again and again',
            'By recalling the meaning and rebuilding an example sentence',
            'By listening for a notification',
          ],
          correctIndex: 1,
          evidence:
              'She retrieved the meaning first, then constructed the sentence.',
        ),
      ],
      wordTr: 'gecikmeli',
      wordEn: 'delayed',
      meaningTr: 'Bir süre geçtikten sonra gerçekleşen.',
      meaningEn: 'Happening after a period of time.',
      exampleTr: 'Gecikmeli hatırlama, yalnızca yeniden okumaktan farklıdır.',
      exampleEn: 'Delayed recall differs from simply rereading.',
    ),
    RecallArticle(
      id: 'bridge_measure',
      titleTr: 'Köprüdeki ölçü çizgisi',
      titleEn: 'The measure mark on the bridge',
      categoryTr: 'AKIL YÜRÜTME',
      categoryEn: 'REASONING',
      bodyTr: 'Kasabanın eski köprüsünde su seviyesini gösteren kırmızı bir çizgi vardı. Yağmurdan sonra çizginin altı görünüyordu, ama görevli Bora köprünün güvenli olduğunu hemen ilan etmedi. Önce sabit taş ölçerle yeni bir okuma yaptı, sonra köprünün altındaki tahliye kanalını kontrol etti. Kanalın ağzına yapraklar dolmuştu. Su seviyesi çizginin altında olsa da akış yavaşlamış, yukarı havzadaki yağış sürüyordu. Bora geçişi kısa süreli kapattı, kanalı temizletti ve ölçümü yeniden yaptı. İkinci okumada su seviyesi düşüyordu. Bora ancak iki ayrı işaret—seviye ve akış—aynı yönde güven verince köprüyü açtı. Kasaba duyurusunda tek bir sayıya değil, kararın hangi koşullarla verildiğine yer verdi.',
      bodyEn: 'An old bridge in town had a red mark for river level. After the rain, the water sat below the mark, but caretaker Bora did not immediately declare the bridge safe. He took a new reading from the fixed stone gauge and inspected the drain beneath the bridge. Leaves had clogged its mouth. The level was below the line, yet the flow had slowed and rain was still falling upstream. Bora briefly closed the crossing, cleared the drain and measured again. The second reading showed the water falling. He reopened the bridge only when two independent signs—the level and the flow—were both reassuring. In the town notice, he explained the conditions behind the decision instead of quoting a single number without context.',
      questionsTr: <RecallQuestion>[
        RecallQuestion(
          prompt: 'Bora neden yalnızca kırmızı çizgiye bakmadı?',
          options: <String>[
            'Ölçer bozulduğu için',
            'Tahliye kanalı tıkalıydı ve yukarıda yağış sürüyordu.',
            'Köprüde kırmızı çizgi yoktu.',
          ],
          correctIndex: 1,
          evidence: 'Seviye çizginin altında olsa da akış yavaşlamış ve yağış sürüyordu.',
        ),
        RecallQuestion(
          prompt: 'Köprüyü hangi durumda yeniden açtı?',
          options: <String>[
            'Tek bir ölçüm çizginin altındayken',
            'Su seviyesi düşerken akış da güven verince',
            'Yağmur yeni başladığında',
          ],
          correctIndex: 1,
          evidence:
              'Karar iki bağımsız işaretin birlikte olumlu olmasına dayandı.',
        ),
      ],
      questionsEn: <RecallQuestion>[
        RecallQuestion(
          prompt: 'Why did Bora look beyond the red level mark?',
          options: <String>[
            'The gauge had broken.',
            'The drain was blocked and rain continued upstream.',
            'The bridge had no red mark.',
          ],
          correctIndex: 1,
          evidence: 'The water was below the mark, but flow was slow and rain was still falling.',
        ),
        RecallQuestion(
          prompt: 'When did Bora reopen the bridge?',
          options: <String>[
            'As soon as one reading was below the line',
            'When the falling level and the flow both looked safe',
            'When the rain had just started',
          ],
          correctIndex: 1,
          evidence:
              'He waited until both independent indicators were reassuring.',
        ),
      ],
      wordTr: 'tahliye',
      wordEn: 'drainage',
      meaningTr: 'Bir yerde biriken suyu uzaklaştırma işi.',
      meaningEn: 'The process of removing excess water from an area.',
      exampleTr: 'Tahliye kanalı yapraklarla tıkanmıştı.',
      exampleEn: 'The drainage channel was blocked with leaves.',
    ),
  ];
}
