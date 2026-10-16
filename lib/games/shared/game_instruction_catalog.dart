import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../theme/studio_visuals.dart';

/// Short, player-facing instructions for active games. Keep the first sentence
/// focused on the objective; the steps explain the first useful actions.
class GameInstruction {
  const GameInstruction({
    required this.summaryTr,
    required this.summaryEn,
    required this.stepsTr,
    required this.stepsEn,
  });

  final String summaryTr;
  final String summaryEn;
  final List<String> stepsTr;
  final List<String> stepsEn;

  String summary(bool english) => english ? summaryEn : summaryTr;
  List<String> steps(bool english) => english ? stepsEn : stepsTr;
}

abstract final class GameInstructionCatalog {
  static const Map<String, GameInstruction> _games = <String, GameInstruction>{
    'mine_detective': GameInstruction(
      summaryTr: 'Sayı ipuçlarını kullanarak mayınları işaretle ve tüm güvenli kareleri aç.',
      summaryEn:
          'Use number clues to flag the mines and reveal every safe cell.',
      stepsTr: <String>[
        'Sayı, çevresindeki sekiz karede kaç mayın bulunduğunu gösterir.',
        'Bayrak modunda şüpheli kareleri işaretle; açma modunda güvenli karelere dokun.',
      ],
      stepsEn: <String>[
        'A number tells you how many mines are in the eight surrounding cells.',
        'Flag suspected mines, then tap cells you can prove are safe.',
      ],
    ),
    'detective_notes': GameInstruction(
      summaryTr: 'Tanık ipuçlarını birleştirip kişi, oda ve eşya eşleşmelerinden tek doğru vakayı çıkar.',
      summaryEn: 'Combine witness clues to find the one valid person, room, and item combination.',
      stepsTr: <String>[
        'Her ipucunu ilgili kategoriyle eşleştir; kesinleşen bilgileri not et.',
        'Birbirini dışlayan seçenekleri ele ve tüm koşulları sağlayan vakayı seç.',
      ],
      stepsEn: <String>[
        'Match each clue to its category and keep track of confirmed facts.',
        'Rule out conflicting options and choose the case that satisfies every clue.',
      ],
    ),
    'balance_scale': GameInstruction(
      summaryTr: 'Terazi ve karşılaştırma ipuçlarından yararlanarak bilinmeyen ağırlıkları bul.',
      summaryEn: 'Use the balance and comparison clues to determine the unknown weights.',
      stepsTr: <String>[
        'Ağırlığı seç, ait olduğu kefeye yerleştir ve terazinin sonucunu gözle.',
        'Eşitlik ve büyüklük ipuçlarını birlikte kullan; bütün kefeleri dengele.',
      ],
      stepsEn: <String>[
        'Select a weight, place it on a pan, and observe the balance.',
        'Combine equality and comparison clues until every scale is balanced.',
      ],
    ),
    'numbers': GameInstruction(
      summaryTr: 'Her turdaki sayı örüntüsünü veya işlemi çöz; istenen eksik değeri doğru hücreye yerleştir.',
      summaryEn: 'Solve each number pattern or operation, then place the missing value in the right cell.',
      stepsTr: <String>[
        'Önce ekrandaki görev kuralını oku; sayıların nasıl değiştiğini incele.',
        'Seçeneğe veya hücreye dokunup cevabı gir, ardından kontrol ederek ilerle.',
      ],
      stepsEn: <String>[
        'Read the round rule first, then look for how the numbers change.',
        'Tap an answer or cell to enter your choice, then check it to continue.',
      ],
    ),
    'number_sort': GameInstruction(
      summaryTr: 'Taşları artan sıraya getir; her hamlede yalnızca boşluğun yanındaki taşı kaydırabilirsin.',
      summaryEn: 'Arrange the tiles in order; each move slides a tile next to the empty space.',
      stepsTr: <String>[
        'Boş kareye komşu taşı seç veya boşluğa doğru sürükle.',
        'Satırları ve boşluğun yerini önceden planlayıp sayıları hedef dizilime getir.',
      ],
      stepsEn: <String>[
        'Tap or drag a tile that is next to the empty space.',
        'Plan around the gap and move the numbers into the target order.',
      ],
    ),
    'target_24': GameInstruction(
      summaryTr: 'Dört kartın tamamını işlem işaretleriyle birleştir ve sonucu 24 yap.',
      summaryEn:
          'Combine all four cards with arithmetic operations to make 24.',
      stepsTr: <String>[
        'İşlem türünü seç, ardından kullanacağın iki kartı sırayla işaretle.',
        'Ara sonucu koruyarak kalan kartları kullan; dört kartın hiçbiri dışarıda kalmasın.',
      ],
      stepsEn: <String>[
        'Choose an operation, then select the two cards you want to combine.',
        'Use the remaining cards and make sure all four contribute to the result.',
      ],
    ),
    'mini_sudoku': GameInstruction(
      summaryTr: 'Boş hücreleri 1–6 ile doldur; her sayı satırda, sütunda ve 2×3 bölgede bir kez bulunsun.',
      summaryEn: 'Fill empty cells with 1–6; use each digit once per row, column, and 2×3 region.',
      stepsTr: <String>[
        'Bir boş hücreyi seç ve aday sayıları satır, sütun ve bölgeden ele.',
        'Çakışma yaratmayan sayıyı gir; tüm tablo tamamlanınca doğrula.',
      ],
      stepsEn: <String>[
        'Select an empty cell and eliminate digits already in its row, column, or region.',
        'Enter a non-conflicting value and verify the completed grid.',
      ],
    ),
    'kenken_cube': GameInstruction(
      summaryTr: 'Satır ve sütun tekrarlarını önleyerek kafeslerdeki işlem hedeflerini tuttur.',
      summaryEn: 'Meet each cage’s arithmetic target without repeating values in rows or columns.',
      stepsTr: <String>[
        'Her kafesin hedef sayısını ve yanındaki işlem işaretini birlikte oku.',
        'Hücreye sayı girerken aynı satır ve sütunda tekrar olmadığını kontrol et.',
      ],
      stepsEn: <String>[
        'Read each cage target together with its operation sign.',
        'Before entering a value, check that it does not repeat in the row or column.',
      ],
    ),
    'hidden_masses': GameInstruction(
      summaryTr: 'Terazi ölçümlerini ve ağırlık ilişkilerini kullanarak bilinmeyen kütleyi hesapla.',
      summaryEn: 'Use balance readings and weight relationships to calculate the unknown mass.',
      stepsTr: <String>[
        'Her ölçümün hangi nesneleri karşılaştırdığını belirle.',
        'Eşitlikleri birleştir, bilinen ağırlıkları çıkar ve sonucu gir.',
      ],
      stepsEn: <String>[
        'Identify which objects each measurement compares.',
        'Combine the equalities, subtract known weights, and enter the result.',
      ],
    ),
    'kakuro': GameInstruction(
      summaryTr: 'Her kesintisiz sayı dizisini çapraz toplam ipuçlarına göre doldur; aynı dizide rakam tekrarlama.',
      summaryEn: 'Fill each run to match its crossing sum clues; do not repeat a digit within a run.',
      stepsTr: <String>[
        'Köşegen ipucundan toplamı ve dizinin yönünü oku.',
        '1–9 rakamlarını, yatay ve dikey toplamları aynı anda sağlayacak biçimde yerleştir.',
      ],
      stepsEn: <String>[
        'Read the diagonal clue to find the sum and direction of its run.',
        'Place digits 1–9 so both the across and down sums work without repeats.',
      ],
    ),
    'blocks': GameInstruction(
      summaryTr: 'Parçaları boş hücrelere yerleştir; tamamlanan satır veya sütunları temizleyip bölüm hedeflerine ulaş.',
      summaryEn: 'Place pieces in empty cells, clear full rows or columns, and reach the chapter goals.',
      stepsTr: <String>[
        'Bir parçaya dokunup kaldır; tahtaya sürükleyerek ya da bırakarak yerleştir.',
        'Parçalar dönmez; sonraki şekillere alan bırak ve gösterilen puan/sıra hedefini tamamla.',
      ],
      stepsEn: <String>[
        'Tap a piece to lift it, then drag or release it onto the board.',
        'Pieces do not rotate; leave room for upcoming shapes and meet the score/line goals.',
      ],
    ),
    'picture_iq': GameInstruction(
      summaryTr: 'Görseldeki dönüşüm veya ilişki kuralını bul ve diziyi tamamlayan parçayı seç.',
      summaryEn: 'Find the visual transformation or relationship and choose the piece that completes the pattern.',
      stepsTr: <String>[
        'Şekil, renk, yön ve konum değişimlerini ayrı ayrı incele.',
        'Kuralı seçeneklere uygula; yalnızca bütün ilişkileri karşılayan yanıtı işaretle.',
      ],
      stepsEn: <String>[
        'Inspect changes in shape, color, direction, and position separately.',
        'Apply the rule to the choices and select the one that satisfies every relation.',
      ],
    ),
    'shape_puzzle': GameInstruction(
      summaryTr: 'Verilen geometrik parçaları döndürüp birleştirerek hedef silüeti boşluk bırakmadan oluştur.',
      summaryEn: 'Rotate and combine the given shapes to form the target silhouette without gaps.',
      stepsTr: <String>[
        'Bir parçayı seç; döndürme veya çevirme kontrolüyle yönünü ayarla.',
        'Parçaları hedef alanla eşleştir ve tüm kareleri kapladığında cevabı doğrula.',
      ],
      stepsEn: <String>[
        'Select a piece and use the rotate or flip controls to orient it.',
        'Fit the pieces to the target and verify once every required cell is covered.',
      ],
    ),
    'memory': GameInstruction(
      summaryTr: 'Tur başında gösterilen ışık, ses veya kart bilgisini aklında tut ve istenen sırayla yeniden üret.',
      summaryEn: 'Remember the lights, sounds, or cards shown in each round and reproduce the requested sequence.',
      stepsTr: <String>[
        'Gösterim sırasında seçim yapma; sıralamayı ve tekrar eden işaretleri izle.',
        'Sıra sana geçtiğinde aynı diziyi uygula; ekrandaki tur kuralına dikkat et.',
      ],
      stepsEn: <String>[
        'Watch the sequence without tapping; note its order and repeated signals.',
        'When it is your turn, replay it exactly and follow the round rule on screen.',
      ],
    ),
    'card_pairs': GameInstruction(
      summaryTr: 'Kartları ikişer aç; aynı görsele sahip çiftleri bulup tüm desteyi eşleştir.',
      summaryEn: 'Reveal two cards at a time, match identical images, and clear the full deck.',
      stepsTr: <String>[
        'İlk karta dokunup görselini hatırla, sonra ikinci kartı aç.',
        'Eşleşme değilse konumları aklında tut; eşleşen çiftler açık kalır.',
      ],
      stepsEn: <String>[
        'Tap one card, remember its image, then reveal a second card.',
        'If they differ, remember their locations; matched pairs stay revealed.',
      ],
    ),
    'focus_filter': GameInstruction(
      summaryTr: 'Hedef şeklin kuralını aklında tut; benzer görünen dikkat dağıtıcıları eleyip yalnızca doğru sinyale dokun.',
      summaryEn: 'Remember the target rule, ignore look-alikes, and tap only the matching signal.',
      stepsTr: <String>[
        'Önce şeklin hangi özelliğinin önemli olduğunu oku; rengi veya deseni yok sayman istenebilir.',
        'Hedefi seç, diğerlerini geç; doğru seriyi korurken yanlış dokunuşlardan kaçın.',
      ],
      stepsEn: <String>[
        'Read which feature matters; the rule may ask you to ignore color or pattern.',
        'Select the target and skip the rest while avoiding false taps.',
      ],
    ),
    'spot_change': GameInstruction(
      summaryTr: 'Önceki ve güncel sahneyi karşılaştır; değişen nesne veya ayrıntıları bularak işaretle.',
      summaryEn: 'Compare the earlier and current scenes, then mark every changed object or detail.',
      stepsTr: <String>[
        'Sahneleri sistemli biçimde tara; konum, renk, şekil ve eksilen nesnelere bak.',
        'Farkı gördüğün bölgeye dokun; aynı noktayı tekrar işaretleme.',
      ],
      stepsEn: <String>[
        'Scan both scenes systematically for changes in position, color, shape, or missing objects.',
        'Tap the changed area and avoid marking the same difference twice.',
      ],
    ),
    'rhythm_memory': GameInstruction(
      summaryTr: 'Ritmi dinle, vurgulu vuruşları ayırt et ve sırayı doğru zamanlamayla tekrar çal.',
      summaryEn: 'Listen to the rhythm, notice accented beats, and replay it with accurate timing.',
      stepsTr: <String>[
        'Örnek ritmi tamamlanana kadar dinle; normal ve vurgulu notaları ayır.',
        'Normal vuruş için dokun, vurgu için basılı tut ve seriyi sürdür.',
      ],
      stepsEn: <String>[
        'Listen to the full example and distinguish normal from accented beats.',
        'Tap for a normal beat, hold for an accent, and keep the sequence going.',
      ],
    ),
    'attention_tunnel': GameInstruction(
      summaryTr: 'Hedef kartın yerini karıştırma boyunca izle; durduğunda doğru hattı veya kartı seç.',
      summaryEn: 'Track the target card through the shuffle, then select its final position.',
      stepsTr: <String>[
        'Karıştırma başlamadan hedefi tanı; hareket ederken gözünü ondan ayırma.',
        'Akış durunca hedefin bulunduğu karta dokun; emin değilsen ipucunu kullan.',
      ],
      stepsEn: <String>[
        'Identify the target before the shuffle and follow it as it moves.',
        'When the motion stops, tap its card; use a hint if you lose track.',
      ],
    ),
    'hanoi': GameInstruction(
      summaryTr: 'Halkaları kurallı biçimde hedef kuleye taşı; büyük halkayı küçük halkanın üzerine koyma.',
      summaryEn: 'Move the rings to the target tower without placing a larger ring on a smaller one.',
      stepsTr: <String>[
        'Kaynak kuleye dokunup en üstteki halkayı seç.',
        'Hedef kuleye dokun; ara kuleleri kullanarak küçük halkaları üstte tut.',
      ],
      stepsEn: <String>[
        'Tap a source tower to select its top ring.',
        'Tap a destination tower and use the spare tower while keeping smaller rings on top.',
      ],
    ),
    'candy_sort': GameInstruction(
      summaryTr: 'Renkli şekerleri kavanozlara ayır; yalnızca üstteki şekeri boş ya da aynı renkli kavanoza taşı.',
      summaryEn: 'Sort colored candies into jars; move only a top candy onto an empty jar or its matching color.',
      stepsTr: <String>[
        'Bir kavanozun üstündeki şekere, ardından uygun boş kavanoza veya aynı renge dokun.',
        'Her kavanoz tek renk olduğunda bölümü tamamla; boş alanı hamlelerini planlamak için sakla.',
      ],
      stepsEn: <String>[
        'Tap a top candy, then tap an empty jar or a jar with the same color.',
        'Finish when every jar contains one color, saving empty space for planning.',
      ],
    ),
    'parking_puzzle': GameInstruction(
      summaryTr: 'Diğer araçları kendi yönlerinde kaydırarak hedef araca çıkışa kadar açık bir yol oluştur.',
      summaryEn: 'Slide the other vehicles along their lanes to clear an exit path for the target car.',
      stepsTr: <String>[
        'Bir araca dokunup sürükle; araçlar yalnızca bulundukları yönde hareket eder.',
        'Önce çıkış yolunu kapatan araçları belirle ve boşluğu adım adım aç.',
      ],
      stepsEn: <String>[
        'Tap and drag a vehicle; each one moves only along its lane.',
        'Find which vehicles block the exit and create space one move at a time.',
      ],
    ),
    'mini_chess_tactics': GameInstruction(
      summaryTr: 'Tahtadaki yasal hamleleri incele ve rakip şahı belirtilen hamle sayısında mat et.',
      summaryEn: 'Inspect the legal moves and checkmate the opposing king within the stated number of moves.',
      stepsTr: <String>[
        'Önce şahın kaçış karelerini ve rakibin savunma taşlarını kontrol et.',
        'Taşını, rakibe yasal kaçış bırakmayacak kareye sürükle veya dokunarak seç.',
      ],
      stepsEn: <String>[
        'Check the king’s escape squares and the opponent’s defending pieces first.',
        'Move your piece to a square that leaves no legal escape from checkmate.',
      ],
    ),
    'word_hunt': GameInstruction(
      summaryTr: 'Listelenen kelimeleri harf tablosunda bul; düz, çapraz veya ters yöndeki harfleri sırayla birleştir.',
      summaryEn: 'Find each listed word in the letter grid by tracing its letters in any allowed direction.',
      stepsTr: <String>[
        'Aradığın kelimenin ilk harfini bul ve olası yönlerde devamını tara.',
        'Harfleri sürükleyerek seç veya başlangıç ve bitiş harflerine dokun.',
      ],
      stepsEn: <String>[
        'Locate the first letter and scan possible directions for the rest of the word.',
        'Drag across the letters or tap the word’s first and last letters.',
      ],
    ),
    'meaning_match': GameInstruction(
      summaryTr: 'Tahtadaki 16 sözcüğü ortak anlam ilişkilerine göre dörderli dört gruba ayır.',
      summaryEn: 'Sort the 16 words into four groups of four based on their shared meaning.',
      stepsTr: <String>[
        'Birbiriyle eş anlamlı, aynı konuya ait veya ortak özelliği olan sözcükleri ara.',
        'Dört sözcüğü seçip grubu gönder; yanlış gruplarda hangi sözcüklerin yakın olduğunu incele.',
      ],
      stepsEn: <String>[
        'Look for synonyms, shared topics, or another precise connection between words.',
        'Select four and submit the group; use near-miss feedback to refine your next choice.',
      ],
    ),
    'proverb_finish': GameInstruction(
      summaryTr: 'Atasözünün anlamını ve bağlamını okuyup eksik bırakılan sözcüğü seçeneklerden tamamla.',
      summaryEn:
          'Use the proverb’s meaning and context to choose the missing word.',
      stepsTr: <String>[
        'Cümleyi baştan sona oku; boşluğun çevresindeki sözcükler anlamı sınırlar.',
        'Atasözünün bilinen kullanımına uyan seçeneği işaretle ve cevabı kontrol et.',
      ],
      stepsEn: <String>[
        'Read the whole sentence; nearby words narrow down the missing meaning.',
        'Choose the option that fits the proverb’s established usage and check your answer.',
      ],
    ),
    'word_wheel': GameInstruction(
      summaryTr: 'Harf çarkında parmağını kaldırmadan harfleri birleştir; gizli kelimeleri bul ve uzun kelimelerle daha fazla puan kazan.',
      summaryEn: 'Swipe through the letter wheel without lifting your finger to find hidden words; longer words earn more points.',
      stepsTr: <String>[
        'Parmağını çarktaki harflerin üzerinden geçir; aynı harfi bir turda ikinci kez seçemezsin.',
        'Sürüklemeyi bitirince kelime kontrol edilir. Buldukların listelenir; ipucu puanını azaltır.',
      ],
      stepsEn: <String>[
        'Move your finger across the wheel; each letter can be used only once per word.',
        'Release to check the word. Found words appear in the list; hints reduce your score.',
      ],
    ),
    'sentence_builder': GameInstruction(
      summaryTr: 'Karışık sözcük bloklarını dilbilgisi ve anlam sırasına koyarak doğru cümleyi kur.',
      summaryEn: 'Arrange the shuffled word blocks by grammar and meaning to build a correct sentence.',
      stepsTr: <String>[
        'Cümlenin özne, yüklem ve tamamlayıcı ilişkisini belirle.',
        'Sözcükleri sırayla seç veya sürükle; anlamlı cümleyi oluşturunca kontrol et.',
      ],
      stepsEn: <String>[
        'Identify how the subject, verb, and modifiers relate.',
        'Select or drag the words into order, then check the completed sentence.',
      ],
    ),
    'near_meaning': GameInstruction(
      summaryTr: 'Hedef sözcüğü cümle içinde değerlendir ve bağlama en uygun yakın anlamı seç.',
      summaryEn: 'Read the target word in context and choose the closest meaning for the sentence.',
      stepsTr: <String>[
        'Yalnızca benzer yazılışa değil, sözcüğün cümledeki görevine ve tonuna bak.',
        'Seçeneği işaretle; geri bildirimde nüans farkını inceleyerek ilerle.',
      ],
      stepsEn: <String>[
        'Look beyond similar spelling: consider the word’s role and tone in the sentence.',
        'Select an option and use the feedback to notice the difference in nuance.',
      ],
    ),
    'letter_maze': GameInstruction(
      summaryTr: 'Harf ve sözcük ipuçlarını çözerek labiryonda doğru yolu bul ve çıkışa ulaş.',
      summaryEn: 'Solve the letter and word clues to choose the correct path through the maze.',
      stepsTr: <String>[
        'Önce ipucunun istediği harfi, heceyi veya sözcük kökünü belirle.',
        'Yalnızca koşula uyan geçidi seç; yanlış dal yerine doğru rotayı sürdür.',
      ],
      stepsEn: <String>[
        'Determine which letter, syllable, or word root the clue is asking for.',
        'Choose only the passage that fits and continue along the correct route.',
      ],
    ),
    'language_detective': GameInstruction(
      summaryTr:
          'Dil iddiasını örnekler ve kanıtlarla sınayıp doğru açıklamayı seç.',
      summaryEn: 'Test each language claim against its examples and evidence, then choose the supported explanation.',
      stepsTr: <String>[
        'İddianın hangi özelliği açıkladığını belirle; karşı örnekleri özellikle ara.',
        'Kanıtla çelişmeyen açıklamayı seç ve gözlem ile çıkarımı ayır.',
      ],
      stepsEn: <String>[
        'Identify the feature a claim is explaining and look deliberately for counterexamples.',
        'Choose the explanation consistent with the evidence and separate observation from inference.',
      ],
    ),
    'story_order': GameInstruction(
      summaryTr: 'Olay kartlarını neden-sonuç ve zaman ipuçlarına göre sıralayıp tutarlı bir hikâye oluştur.',
      summaryEn: 'Order the event cards using time and cause-and-effect clues to create a coherent story.',
      stepsTr: <String>[
        'Başlangıç, değişim ve sonuç bildiren kartları ayırt et.',
        'Kartları sıraya sürükle; olayların birbirini mantıklı biçimde izlediğini doğrula.',
      ],
      stepsEn: <String>[
        'Identify cards that establish the beginning, turning point, and outcome.',
        'Drag cards into order and verify that each event follows logically from the last.',
      ],
    ),
    'reflex': GameInstruction(
      summaryTr: 'Ekrandaki tur kuralına göre hedefe hızlı ve doğru tepki ver; tuzaklara dokunma.',
      summaryEn: 'React quickly to the target described by the round rule and avoid traps.',
      stepsTr: <String>[
        'Hedefin ne olduğunu tur başlamadan oku; bazı turlarda belirli renk veya şekil istenir.',
        'Sinyal görünür görünmez doğru hedefe dokun; erken ve yanlış dokunuşlardan kaçın.',
      ],
      stepsEn: <String>[
        'Read the target before the round; some rounds require a specific color or shape.',
        'Tap the correct target as soon as it appears, without tapping early or on a decoy.',
      ],
    ),
    'slide_sweets': GameInstruction(
      summaryTr: 'Şekerler kavşaklara ulaşmadan yön kapılarını ayarlayıp her şekli doğru çıkışa gönder.',
      summaryEn: 'Set each direction gate before sweets reach it and route every shape to its matching exit.',
      stepsTr: <String>[
        'Kavşağa dokun ve kullanılabilir yönlerden birini seç.',
        'Şeker hareket etmeden önce rotayı kur; yanlış kapıdan çıkan şekil hedefi kaçırır.',
      ],
      stepsEn: <String>[
        'Tap an intersection and choose one of its available directions.',
        'Set the route before the sweet arrives; a wrong gate sends it past its target.',
      ],
    ),
    'reversi_arena': GameInstruction(
      summaryTr: 'Boş kareye taş koyup rakip taşları kendi taşların arasında aynı çizgide sıkıştır; çevirdiğin taşlarla oyun sonunda rakibinden fazla taşa ulaş.',
      summaryEn: 'Place on an empty square to trap opponent discs in a straight line between your discs; flip them and finish with more discs than your opponent.',
      stepsTr: <String>[
        'Yalnızca ekrandaki yasal hamle noktalarından birine dokun; hamlen rakip taşlarını aynı yönde iki kendi taşın arasında bırakmalı.',
        'Yatay, dikey ve çapraz çizgileri değerlendir. Hamle kalmadığında oyun biter; daha çok taşı olan kazanır.',
      ],
      stepsEn: <String>[
        'Tap a marked legal square that leaves one or more opponent discs between two of your discs in a straight line.',
        'Check horizontal, vertical, and diagonal lines. The game ends when neither player can move; the player with more discs wins.',
      ],
    ),
    'picross_master': GameInstruction(
      summaryTr: 'Satır ve sütun ipuçlarındaki sayıları doldurulacak hücre grupları olarak okuyup gizli silüeti tamamla.',
      summaryEn: 'Read row and column numbers as groups of filled cells and reveal the hidden silhouette.',
      stepsTr: <String>[
        'Sayılar, ilgili çizgide art arda dolu hücre gruplarının uzunluğunu ve sırasını gösterir.',
        'DOLDUR ile dolu, BOŞ ile boş hücreyi işaretle; ayrı gruplar arasına en az bir boş kare koy.',
      ],
      stepsEn: <String>[
        'Numbers give the lengths and order of consecutive filled groups in each line.',
        'Mark cells FILLED or EMPTY; leave at least one blank cell between separate groups.',
      ],
    ),
    'arrow_route': GameInstruction(
      summaryTr: 'Okları tahtadan güvenle çıkaracak sırayı bul; bir oku hareket ettirmeden önce yolunun açık olduğuna bak.',
      summaryEn: 'Find the order that clears the arrows from the board, checking each path before moving it.',
      stepsTr: <String>[
        'Okun yönündeki çıkış çizgisini takip et; önünde başka bir ok varsa o engeli önce çöz.',
        'Çıkış yolu açık olan oka dokun; tüm oklar kalkana kadar devam et.',
      ],
      stepsEn: <String>[
        'Trace the arrow toward its exit; if another arrow blocks the path, resolve that one first.',
        'Tap an arrow with a clear route and continue until the board is empty.',
      ],
    ),
    'loop_master': GameInstruction(
      summaryTr: 'Sayı ipuçlarına uyan tek kapalı döngüyü çiz; çizgi dallanmasın ve kendi üzerine kesişmesin.',
      summaryEn: 'Draw the single closed loop that satisfies the clues without branches or crossings.',
      stepsTr: <String>[
        'Her hücredeki sayı, çevresindeki kenarlardan kaçının çizgi olacağını söyler.',
        'Komşu kenarları seçerek tek bir kesintisiz halka kur ve bütün ipuçlarını doğrula.',
      ],
      stepsEn: <String>[
        'A number in a cell tells how many of its surrounding edges belong to the loop.',
        'Select neighboring edges to form one continuous ring, then verify every clue.',
      ],
    ),
    'island_sea': GameInstruction(
      summaryTr: 'Sayıların gösterdiği büyüklükte adalar oluştur; adalar ayrık, çevredeki deniz ise bağlı kalmalı.',
      summaryEn: 'Build islands of the indicated sizes; islands stay separate while the surrounding sea connects.',
      stepsTr: <String>[
        'Her sayı, o adada bulunması gereken toplam kara hücresi sayısıdır.',
        'Kareye dokunarak ADA veya DENİZ seç; adaları çapraz değil kenardan ayır ve denizi tek parça tut.',
      ],
      stepsEn: <String>[
        'Each number gives the total number of land cells in its island.',
        'Tap to mark LAND or SEA; separate islands by edges and keep the sea in one connected area.',
      ],
    ),
    'futoshiki': GameInstruction(
      summaryTr: 'Her satır ve sütuna sayıları tekrarsız yerleştir; komşu hücrelerdeki büyüktür/küçüktür işaretlerine uy.',
      summaryEn: 'Place non-repeating values in each row and column while obeying every inequality sign.',
      stepsTr: <String>[
        'Boş hücreyi seçip izin verilen sayıyı gir; aynı sayı satır veya sütunda tekrar edemez.',
        'Komşu sayıları < ve > işaretlerine göre karşılaştır, sonra tabloyu doğrula.',
      ],
      stepsEn: <String>[
        'Select an empty cell and enter an allowed value; rows and columns cannot repeat.',
        'Compare neighboring values against the < and > signs, then verify the grid.',
      ],
    ),
    'skyscrapers': GameInstruction(
      summaryTr: 'Binaları satır ve sütunlarda tekrarsız yerleştir; kenar ipuçlarındaki kadar bina görünür bırak.',
      summaryEn: 'Place building heights without repeats and match the visible counts shown around the grid.',
      stepsTr: <String>[
        'Her kenar sayısı, o yönden bakıldığında görülecek bina sayısını belirtir.',
        'Bir hücreyi seçip yüksekliği gir; öndeki yüksek binaların arkadakileri kapattığını hesaba kat.',
      ],
      stepsEn: <String>[
        'Each edge clue counts how many buildings are visible from that direction.',
        'Select a cell and enter a height; taller buildings hide the shorter ones behind them.',
      ],
    ),
    'hitori': GameInstruction(
      summaryTr: 'Her satır ve sütundaki tekrarları gölgele; gölgelenmeyen hücreler tek bir bağlı beyaz alan oluşturmalı.',
      summaryEn: 'Shade duplicate values in every row and column while keeping the remaining cells connected.',
      stepsTr: <String>[
        'Tekrarlanan sayılardan hangisinin gölgelenmesi gerektiğini kesişen satır ve sütunlardan çıkar.',
        'Gölge hücreleri kenardan temas ettirme; beyaz alanı bölmeden tüm tekrarları kaldır.',
      ],
      stepsEn: <String>[
        'Use the crossing row and column constraints to decide which duplicate to shade.',
        'Do not let shaded cells touch by an edge, and keep all unshaded cells connected.',
      ],
    ),
    'city_atlas': GameInstruction(
      summaryTr: 'Coğrafi ipuçlarından ili çıkar, adını yaz ve doğru yanıtı haritadaki konumla doğrula.',
      summaryEn: 'Infer the province from geographic clues, type its name, and confirm its map location.',
      stepsTr: <String>[
        'Bölge, komşuluk ve yön ipuçlarını haritadaki şekil ve konumlarla karşılaştır.',
        'İl adını cevap alanına yaz; doğruysa hedef il haritada yanıp söner.',
      ],
      stepsEn: <String>[
        'Compare region, neighbor, and direction clues with the map’s shapes and positions.',
        'Type the province name; the correct province flashes on the map.',
      ],
    ),
    'world_atlas': GameInstruction(
      summaryTr: 'Bölge, başkent ve coğrafya ipuçlarından ülkeyi bul; adını yazarak dünya haritasında doğrula.',
      summaryEn: 'Use region, capital, and geography clues to identify a country and verify it on the world map.',
      stepsTr: <String>[
        'İpuçlarında geçen kıta, komşular, kıyı ve yön bilgisini birlikte değerlendir.',
        'Ülke adını yaz; doğru cevapta hedef ülke harita üzerinde vurgulanır.',
      ],
      stepsEn: <String>[
        'Combine clues about the continent, neighbors, coastline, and direction.',
        'Type the country name; the correct country is highlighted on the map.',
      ],
    ),
    'katamino_workshop': GameInstruction(
      summaryTr: 'Seçtiğin poliomino parçalarını tahtaya döndürüp/çevirerek tüm hedef hücreleri boşluksuz kapla.',
      summaryEn: 'Rotate and flip the selected polyominoes to cover every target cell without gaps.',
      stepsTr: <String>[
        'Alttan bir parça seç; döndürme veya aynalama düğmeleriyle yönünü değiştir.',
        'Tahtada dokunduğun en uygun hücreye yerleşir; tüm parçalar sığana dek düzeni planla.',
      ],
      stepsEn: <String>[
        'Select a piece below and change its orientation with the rotate or mirror controls.',
        'It snaps to the best fitting cells you touch; plan the layout until all pieces fit.',
      ],
    ),
    'single_stroke': GameInstruction(
      summaryTr: 'Başlangıç düğümünden başlayıp her çizgiyi tam bir kez geçerek bitiş bayrağına ulaş.',
      summaryEn: 'Start at the marked node and reach the flag while traversing each line exactly once.',
      stepsTr: <String>[
        'Başlangıç işaretine dokunup parmağını kaldırmadan bağlı düğümler boyunca sürükle.',
        'Bir çizgiyi ikinci kez kullanamazsın; çıkmazları önceden hesaplayıp bayrağa var.',
      ],
      stepsEn: <String>[
        'Touch the start marker and drag through connected nodes without lifting your finger.',
        'Each line can be used only once; plan around dead ends and finish at the flag.',
      ],
    ),
    'arrow_maze': GameInstruction(
      summaryTr: 'Okların yönünü ve etkisini kullanarak taşı güvenli güzergâhtan çıkışa ulaştır.',
      summaryEn: 'Use the arrows’ directions and effects to guide the token safely to the exit.',
      stepsTr: <String>[
        'Tahtadaki okların gösterdiği hareketi ve engellerin rotayı nasıl değiştirdiğini incele.',
        'Bir sonraki güvenli kareyi seç; hedefe giderken tuzak veya duvara çarpmamaya dikkat et.',
      ],
      stepsEn: <String>[
        'Inspect the movement each arrow indicates and how obstacles change the route.',
        'Choose the next safe square and avoid traps or walls on the way to the exit.',
      ],
    ),
  };

  static GameInstruction? forGame(String gameId) => _games[gameId];

  /// Only guides for player-facing games are part of the active catalog.
  /// Legacy guides remain available through [forGame] for saved routes, but
  /// retired games must not make the active catalog contract drift.
  static Set<String> get gameIds => StudioGameCatalog.games
      .where((game) => game.isPlayable)
      .map((game) => game.id)
      .where(_games.containsKey)
      .toSet();
}

class GameInstructionCard extends StatefulWidget {
  const GameInstructionCard({
    super.key,
    required this.gameId,
    required this.english,
    this.initiallyExpanded = true,
  });

  final String gameId;
  final bool english;
  final bool initiallyExpanded;

  @override
  State<GameInstructionCard> createState() => _GameInstructionCardState();
}

class _GameInstructionCardState extends State<GameInstructionCard> {
  // Show the actionable instructions before the player starts a level. The
  // summary alone is often not enough to explain a game's first move.
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final GameInstruction? instruction = GameInstructionCatalog.forGame(
      widget.gameId,
    );
    if (instruction == null) return const SizedBox.shrink();

    final List<String> steps = instruction.steps(widget.english);
    return Semantics(
      container: true,
      label: widget.english ? 'How to play' : 'Nasıl oynanır?',
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        decoration: BoxDecoration(
          color: StudioVisuals.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: StudioVisuals.line),
          boxShadow: StudioVisuals.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 13, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 19,
                        color: StudioVisuals.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.english ? 'HOW TO PLAY' : 'NASIL OYNANIR?',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.tealInk,
                            fontSize: 11,
                            letterSpacing: .75,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: StudioVisuals.muted,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    instruction.summary(widget.english),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.ink,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: _expanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: Column(
                              children: <Widget>[
                                for (
                                  int index = 0;
                                  index < steps.length;
                                  index++
                                )
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index == steps.length - 1 ? 0 : 7,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: 19,
                                          height: 19,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: StudioVisuals.tealSoft,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontFamily: 'Roboto',
                                              color: StudioVisuals.tealInk,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            steps[index],
                                            style: const TextStyle(
                                              fontFamily: 'Roboto',
                                              color: StudioVisuals.muted,
                                              fontSize: 12,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
