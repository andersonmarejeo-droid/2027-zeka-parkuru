import 'dart:math' as math;

import '../shared/content_seed.dart';

class NearMeaningCard {
  const NearMeaningCard({
    required this.id,
    required this.minimumStage,
    required this.prefixTr,
    required this.targetTr,
    required this.suffixTr,
    required this.prefixEn,
    required this.targetEn,
    required this.suffixEn,
    required this.optionsTr,
    required this.optionsEn,
    required this.correctOptionIndex,
    required this.contextTr,
    required this.contextEn,
    required this.explanationTr,
    required this.explanationEn,
    required this.nearWordsTr,
    required this.nearWordsEn,
  });

  final String id;
  final int minimumStage;
  final String prefixTr;
  final String targetTr;
  final String suffixTr;
  final String prefixEn;
  final String targetEn;
  final String suffixEn;
  final List<String> optionsTr;
  final List<String> optionsEn;
  final int correctOptionIndex;
  final String contextTr;
  final String contextEn;
  final String explanationTr;
  final String explanationEn;
  final List<String> nearWordsTr;
  final List<String> nearWordsEn;
}

class NearMeaningBoardCard {
  const NearMeaningBoardCard({required this.card, required this.optionOrder});

  final NearMeaningCard card;
  final List<int> optionOrder;

  int get correctOptionIndex => optionOrder.indexOf(card.correctOptionIndex);
}

/// Context-first lexical nuance boards; answer shuffles are seeded for QA.
class NearMeaningScenario {
  const NearMeaningScenario({
    required this.stage,
    required this.cards,
    required this.isPractice,
    required this.round,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;

  static const List<NearMeaningCard> _bank = <NearMeaningCard>[
    NearMeaningCard(
      id: 'inspect_figures',
      minimumStage: 1,
      prefixTr: 'Yayımlanmadan önce rapordaki sayıları ',
      targetTr: 'inceledi',
      suffixTr: '.',
      prefixEn: 'Before publication, she ',
      targetEn: 'examined',
      suffixEn: ' the figures in the report.',
      optionsTr: <String>[
        'Sayıları ve ayrıntıları dikkatle kontrol etti.',
        'Raporu daha kısa hâle getirip özetledi.',
        'Raporun yayımlanmasına izin verdi.',
        'Sayıları başka bir değerle değiştirdi.',
      ],
      optionsEn: <String>[
        'Checked the figures and details carefully.',
        'Shortened the report into a summary.',
        'Gave permission to publish the report.',
        'Replaced the figures with different values.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Rakamlar yayıma gidecek bir raporda doğrulanıyor.',
      contextEn: 'Numbers in a report are being verified before release.',
      explanationTr:
          '“İncelemek” burada ayrıntıları dikkatle kontrol etmektir.',
      explanationEn: 'Here “examine” means to inspect details carefully.',
      nearWordsTr: <String>['gözden geçirmek', 'kontrol etmek'],
      nearWordsEn: <String>['review', 'check'],
    ),
    NearMeaningCard(
      id: 'hesitant_voice',
      minimumStage: 1,
      prefixTr: 'Kalabalıkta fikrini söylemeye ',
      targetTr: 'çekindi',
      suffixTr: '.',
      prefixEn: 'In the crowded room, he ',
      targetEn: 'hesitated',
      suffixEn: ' to share his view.',
      optionsTr: <String>[
        'Söylemek istedi ama cesaret edemedi.',
        'Fikrini yüksek sesle ve kesin biçimde savundu.',
        'Konuşmayı herkesten önce bitirdi.',
        'Fikrini daha sonra değiştirmeye karar verdi.',
      ],
      optionsEn: <String>[
        'Wanted to speak but did not feel able to.',
        'Defended his view loudly and firmly.',
        'Finished speaking before everyone else.',
        'Decided to change his view later.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Kişi fikrini dile getirmekte tereddüt ediyor.',
      contextEn: 'The person is unsure about voicing an opinion.',
      explanationTr: '“Çekinmek” bu cümlede isteksizlikten çok tereddüttür.',
      explanationEn: 'In this context, “hesitate” signals reluctance or doubt.',
      nearWordsTr: <String>['tereddüt etmek', 'ürkek davranmak'],
      nearWordsEn: <String>['be reluctant', 'hold back'],
    ),
    NearMeaningCard(
      id: 'temporary_fix',
      minimumStage: 1,
      prefixTr: 'Kalıcı parça gelene kadar ekip ',
      targetTr: 'geçici',
      suffixTr: ' bir çözüm kullandı.',
      prefixEn: 'Until the permanent part arrived, the team used a ',
      targetEn: 'temporary',
      suffixEn: ' fix.',
      optionsTr: <String>[
        'Yalnızca kısa bir süre için geçerli olan.',
        'Sorunun kaynağını tamamen ortadan kaldıran.',
        'Önceden denenmiş ve kesin sonuç veren.',
        'Her koşulda değişmeden kalan.',
      ],
      optionsEn: <String>[
        'Intended to last only for a short time.',
        'Completely removing the source of the problem.',
        'Previously tested with a guaranteed result.',
        'Remaining unchanged in every circumstance.',
      ],
      correctOptionIndex: 0,
      contextTr:
          'Ekip, kalıcı parça ulaşana dek idare edecek bir çözüm seçiyor.',
      contextEn: 'The fix is used only while the lasting part is unavailable.',
      explanationTr: '“Geçici” kalıcı olmayan, sınırlı süreli çözümü niteler.',
      explanationEn: '“Temporary” describes something that will not last.',
      nearWordsTr: <String>['kısa süreli', 'muvakkat'],
      nearWordsEn: <String>['short-term', 'provisional'],
    ),
    NearMeaningCard(
      id: 'precise_instruction',
      minimumStage: 1,
      prefixTr: 'Kutudaki ',
      targetTr: 'kesin',
      suffixTr: ' ölçüler parçanın uyup uymadığını gösterdi.',
      prefixEn: 'The ',
      targetEn: 'exact',
      suffixEn: ' measurements on the box showed whether the part would fit.',
      optionsTr: <String>[
        'Açıkça belirlenmiş, yaklaşık olmayan.',
        'Birçok yoruma açık ve belirsiz.',
        'Sadece öneri olarak sunulmuş.',
        'Daha sonra değişmesi planlanmış.',
      ],
      optionsEn: <String>[
        'Clearly specified rather than approximate.',
        'Vague and open to many interpretations.',
        'Offered only as a suggestion.',
        'Planned to change later.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Ölçü, parçanın fiziksel olarak uyup uymayacağını belirliyor.',
      contextEn: 'The measurement determines whether a part physically fits.',
      explanationTr: 'Burada “kesin”, ölçünün tam ve net olduğunu anlatır.',
      explanationEn: 'Here “exact” means precise rather than approximate.',
      nearWordsTr: <String>['tam', 'net'],
      nearWordsEn: <String>['precise', 'specific'],
    ),
    NearMeaningCard(
      id: 'careful_craft',
      minimumStage: 1,
      prefixTr: 'Usta, ahşap yüzeyi ',
      targetTr: 'özenle',
      suffixTr: ' zımparaladı.',
      prefixEn: 'The craftsperson sanded the wooden surface ',
      targetEn: 'carefully',
      suffixEn: '.',
      optionsTr: <String>[
        'Ayrıntılara dikkat ederek, titizlikle.',
        'Daha kısa sürsün diye aceleyle.',
        'Yalnızca görünür bölümünü.',
        'Önceden ölçmeden, rastgele.',
      ],
      optionsEn: <String>[
        'With attention to detail and care.',
        'In a hurry to finish sooner.',
        'Only on the visible section.',
        'Randomly, without measuring first.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Yüzey, işçilik kalitesi için dikkatle hazırlanıyor.',
      contextEn: 'The surface is prepared with attention to workmanship.',
      explanationTr: '“Özenle” eylemin dikkatli ve titiz yapıldığını belirtir.',
      explanationEn: '“Carefully” describes an attentive, deliberate action.',
      nearWordsTr: <String>['titizlikle', 'dikkatlice'],
      nearWordsEn: <String>['meticulously', 'attentively'],
    ),
    NearMeaningCard(
      id: 'postpone_meeting',
      minimumStage: 3,
      prefixTr: 'Teknik arıza yüzünden toplantıyı yarına ',
      targetTr: 'ertelediler',
      suffixTr: '.',
      prefixEn: 'Because of a technical fault, they ',
      targetEn: 'postponed',
      suffixEn: ' the meeting until tomorrow.',
      optionsTr: <String>[
        'Toplantıyı daha ileri bir zamana bıraktılar.',
        'Toplantıyı tamamen iptal ettiler.',
        'Toplantıyı daha erken bir saate aldılar.',
        'Toplantının süresini kısalttılar.',
      ],
      optionsEn: <String>[
        'Moved the meeting to a later time.',
        'Cancelled the meeting entirely.',
        'Moved the meeting to an earlier time.',
        'Shortened the meeting duration.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Toplantı yapılacak; yalnızca zamanı değişiyor.',
      contextEn: 'The meeting will still happen; only its timing changes.',
      explanationTr: '“Ertelemek” iptal etmek değil, daha sonraya almaktır.',
      explanationEn: '“Postpone” moves something later; it does not cancel it.',
      nearWordsTr: <String>['geciktirmek', 'sonraya bırakmak'],
      nearWordsEn: <String>['delay', 'defer'],
    ),
    NearMeaningCard(
      id: 'persuade_neighbour',
      minimumStage: 3,
      prefixTr: 'Sakin açıklaması komşusunu planı denemeye ',
      targetTr: 'ikna etti',
      suffixTr: '.',
      prefixEn: 'Her calm explanation ',
      targetEn: 'persuaded',
      suffixEn: ' her neighbor to try the plan.',
      optionsTr: <String>[
        'Komşusunun kabul etmesini sağladı.',
        'Komşusuna planı yalnızca hatırlattı.',
        'Komşusunun planı unutmasına yol açtı.',
        'Komşusunu planı tek başına hazırlamaya zorladı.',
      ],
      optionsEn: <String>[
        'Led the neighbor to agree to try it.',
        'Only reminded the neighbor about the plan.',
        'Caused the neighbor to forget the plan.',
        'Forced the neighbor to prepare it alone.',
      ],
      correctOptionIndex: 0,
      contextTr:
          'Komşu, açıklamadan sonra gönüllü olarak denemeyi kabul ediyor.',
      contextEn: 'After the explanation, the neighbor agrees to try it.',
      explanationTr:
          '“İkna etmek” baskı kurmadan birini bir düşünceye yaklaştırmaktır.',
      explanationEn: 'To persuade is to bring someone around to an idea.',
      nearWordsTr: <String>['inandırmak', 'razı etmek'],
      nearWordsEn: <String>['convince', 'win over'],
    ),
    NearMeaningCard(
      id: 'uncertain_forecast',
      minimumStage: 3,
      prefixTr: 'Yeni veriler gelmeden tahmin ',
      targetTr: 'belirsiz',
      suffixTr: ' kaldı.',
      prefixEn: 'Until new data arrived, the forecast remained ',
      targetEn: 'uncertain',
      suffixEn: '.',
      optionsTr: <String>[
        'Sonucu açıkça kestirilemeyen.',
        'Doğruluğu deneyle kanıtlanmış.',
        'Herkesçe aynı biçimde yorumlanan.',
        'Kesin bir karara bağlanmış.',
      ],
      optionsEn: <String>[
        'Not possible to predict with confidence.',
        'Proven accurate through an experiment.',
        'Interpreted the same way by everyone.',
        'Settled with a definite decision.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Tahmin için henüz yeterli veri yok.',
      contextEn: 'There is not enough evidence to settle the forecast.',
      explanationTr: '“Belirsiz” sonucun henüz netleşmediğini söyler.',
      explanationEn: '“Uncertain” means the outcome is not yet clear.',
      nearWordsTr: <String>['net olmayan', 'kuşkulu'],
      nearWordsEn: <String>['unclear', 'unsettled'],
    ),
    NearMeaningCard(
      id: 'sense_of_change',
      minimumStage: 3,
      prefixTr: 'Havadaki değişimi bulutlardan ',
      targetTr: 'sezdi',
      suffixTr: '.',
      prefixEn: 'From the clouds, she ',
      targetEn: 'sensed',
      suffixEn: ' that the weather was changing.',
      optionsTr: <String>[
        'Kesin kanıt olmadan bir ipucundan anlayıp tahmin etti.',
        'Değişimi araçla ölçüp sayısal sonucunu buldu.',
        'Hava değişikliğini başkalarına duyurdu.',
        'Bulutların yönünü isteyerek değiştirdi.',
      ],
      optionsEn: <String>[
        'Inferred a change from a clue without exact proof.',
        'Measured the change and calculated a number.',
        'Announced the weather change to other people.',
        'Intentionally changed the direction of the clouds.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Kişi ölçüm yapmıyor; gözleminden bir sonuç çıkarıyor.',
      contextEn: 'She is drawing an inference from an observation.',
      explanationTr:
          '“Sezmek” doğrudan ölçmekten çok işaretlerden kavramaktır.',
      explanationEn:
          'To “sense” is to infer from signs, not to measure directly.',
      nearWordsTr: <String>['hissetmek', 'kestirmek'],
      nearWordsEn: <String>['detect', 'intuit'],
    ),
    NearMeaningCard(
      id: 'savings_choice',
      minimumStage: 3,
      prefixTr: 'Geliri azalınca gereksiz harcamalardan ',
      targetTr: 'kaçındı',
      suffixTr: '.',
      prefixEn: 'When her income fell, she ',
      targetEn: 'avoided',
      suffixEn: ' unnecessary spending.',
      optionsTr: <String>[
        'Bir davranışı yapmamaya özellikle dikkat etti.',
        'Harcamalarını başkalarına devretti.',
        'Gereksiz alışverişleri erteleyip sonra yaptı.',
        'Gelirini artırmak için borç aldı.',
      ],
      optionsEn: <String>[
        'Made a deliberate effort not to do something.',
        'Transferred her expenses to someone else.',
        'Delayed unnecessary purchases but made them later.',
        'Borrowed money to increase her income.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Kişi belirli bir harcama türünü yapmamayı seçiyor.',
      contextEn: 'She chooses not to make a particular kind of purchase.',
      explanationTr: '“Kaçınmak”, istenmeyen bir eyleme yönelmemektir.',
      explanationEn: 'To “avoid” is to keep oneself from an unwanted action.',
      nearWordsTr: <String>['sakınmak', 'uzak durmak'],
      nearWordsEn: <String>['refrain from', 'steer clear of'],
    ),
    NearMeaningCard(
      id: 'reflect_values',
      minimumStage: 5,
      prefixTr: 'Yeni tasarım, mahallenin ortak değerlerini ',
      targetTr: 'yansıtıyor',
      suffixTr: '.',
      prefixEn: 'The new design ',
      targetEn: 'reflects',
      suffixEn: ' the neighborhood’s shared values.',
      optionsTr: <String>[
        'Bu değerleri görünür biçimde temsil ediyor.',
        'Bu değerleri tartışmasız biçimde kanıtlıyor.',
        'Bu değerleri geçmişte bırakıyor.',
        'Bu değerleri yalnızca ölçüp sayıyor.',
      ],
      optionsEn: <String>[
        'Represents those values in a visible way.',
        'Proves those values beyond any doubt.',
        'Leaves those values in the past.',
        'Only measures those values numerically.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Tasarım, topluluğun benimsediği şeyleri simgeliyor.',
      contextEn: 'The design expresses what the community values.',
      explanationTr:
          '“Yansıtmak” burada bir niteliği temsil etmek anlamındadır.',
      explanationEn: 'Here “reflect” means to represent or express a quality.',
      nearWordsTr: <String>['temsil etmek', 'aksettirmek'],
      nearWordsEn: <String>['represent', 'express'],
    ),
    NearMeaningCard(
      id: 'defend_position',
      minimumStage: 5,
      prefixTr: 'Avukat, kararın neden değiştirilmesi gerektiğini ',
      targetTr: 'savundu',
      suffixTr: '.',
      prefixEn: 'The lawyer ',
      targetEn: 'argued',
      suffixEn: ' that the decision should be changed.',
      optionsTr: <String>[
        'Gerekçeler sunarak kendi görüşünü destekledi.',
        'Kararı tartışmadan olduğu gibi kabul etti.',
        'Kararı başkalarına duyurmakla yetindi.',
        'Kararla ilgili kanıtları sakladı.',
      ],
      optionsEn: <String>[
        'Supported a position by giving reasons.',
        'Accepted the decision without discussion.',
        'Only announced the decision to others.',
        'Hid the evidence related to the decision.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Avukat, değişiklik talebini gerekçelerle destekliyor.',
      contextEn: 'The lawyer supports a request for change with reasons.',
      explanationTr: '“Savunmak” bu bağlamda bir görüşü gerekçelendirmektir.',
      explanationEn: 'Here “argue” means to support a position with reasons.',
      nearWordsTr: <String>['gerekçelendirmek', 'müdafaa etmek'],
      nearWordsEn: <String>['support', 'make the case for'],
    ),
    NearMeaningCard(
      id: 'mitigate_harm',
      minimumStage: 5,
      prefixTr: 'Yeni filtreler, atölyenin çevreye verdiği zararı ',
      targetTr: 'azalttı',
      suffixTr: ' ama tamamen bitirmedi.',
      prefixEn: 'The new filters ',
      targetEn: 'reduced',
      suffixEn: ' the workshop’s environmental harm but did not end it.',
      optionsTr: <String>[
        'Zararı daha düşük bir düzeye indirdi.',
        'Zararı kesin olarak ortadan kaldırdı.',
        'Zararı başka bir bölgeye taşıdı.',
        'Zararın ölçülmesini imkânsız kıldı.',
      ],
      optionsEn: <String>[
        'Brought the harm down to a lower level.',
        'Removed the harm completely and permanently.',
        'Moved the harm to a different area.',
        'Made the harm impossible to measure.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Cümle özellikle zararın tamamen bitmediğini söylüyor.',
      contextEn: 'The sentence explicitly says the harm did not disappear.',
      explanationTr: '“Azaltmak” miktarı düşürür; “ortadan kaldırmak” kadar güçlü değildir.',
      explanationEn:
          '“Reduce” lowers an amount; it is weaker than “eliminate”.',
      nearWordsTr: <String>['hafifletmek', 'düşürmek'],
      nearWordsEn: <String>['lessen', 'lower'],
    ),
    NearMeaningCard(
      id: 'brief_allocation',
      minimumStage: 5,
      prefixTr: 'Konuşmacı sürenin son bölümünü soru-cevaba ',
      targetTr: 'ayırdı',
      suffixTr: '.',
      prefixEn: 'The speaker ',
      targetEn: 'set aside',
      suffixEn: ' the final part of the session for questions.',
      optionsTr: <String>[
        'Belirli bir amaç için kullanmak üzere tahsis etti.',
        'Soruları oturumdan tamamen çıkardı.',
        'Konuşmanın sonunu beklenmedik biçimde uzattı.',
        'Süreyi eşit parçalara bölüp dağıtmadı.',
      ],
      optionsEn: <String>[
        'Reserved it for a specific purpose.',
        'Removed all questions from the session.',
        'Unexpectedly extended the end of the talk.',
        'Did not divide and distribute the time evenly.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Zamanın belirli bir bölümü soru-cevap amacıyla planlandı.',
      contextEn: 'A specific portion of time is reserved for questions.',
      explanationTr:
          '“Ayırmak” bu cümlede bir kaynağı belli işe tahsis etmektir.',
      explanationEn: 'Here “set aside” means to reserve a resource for a use.',
      nearWordsTr: <String>['tahsis etmek', 'özgülemek'],
      nearWordsEn: <String>['reserve', 'allocate'],
    ),
    NearMeaningCard(
      id: 'plausible_reason',
      minimumStage: 7,
      prefixTr: 'Arşivdeki kayıtlar bu açıklamayı ',
      targetTr: 'makul',
      suffixTr: ' kılıyor, ancak tek başına kanıtlamıyor.',
      prefixEn: 'The archive records make this explanation ',
      targetEn: 'plausible',
      suffixEn: ', but do not prove it on their own.',
      optionsTr: <String>[
        'Eldeki bilgilerle akla yatkın görünen.',
        'Tüm kuşkuları gidererek kesinleşen.',
        'Olasılığı bulunmadığı için dışlanan.',
        'Kanıtla çeliştiği hâlde kabul edilen.',
      ],
      optionsEn: <String>[
        'Reasonable in light of the available information.',
        'Established with every doubt removed.',
        'Ruled out as having no possibility.',
        'Accepted despite contradicting the evidence.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Açıklama makul bulunuyor ama kanıtlanmış sayılmıyor.',
      contextEn: 'The explanation seems reasonable but remains unproven.',
      explanationTr:
          '“Makul”, kanıtlanmış demek değildir; akla uygun demektir.',
      explanationEn: '“Plausible” means reasonable, not conclusively proven.',
      nearWordsTr: <String>['akla yatkın', 'olası'],
      nearWordsEn: <String>['reasonable', 'credible'],
    ),
    NearMeaningCard(
      id: 'implicit_request',
      minimumStage: 7,
      prefixTr: 'Mesajda açık bir talep yoktu; yine de yardım beklentisi ',
      targetTr: 'örtüktü',
      suffixTr: '.',
      prefixEn:
          'The message made no direct request, yet the wish for help was ',
      targetEn: 'implicit',
      suffixEn: '.',
      optionsTr: <String>[
        'Doğrudan söylenmeden sezdirilmişti.',
        'Büyük harflerle özellikle vurgulanmıştı.',
        'Anlamı olmayan sözlerle gizlenmişti.',
        'Herkesçe açıkça reddedilmişti.',
      ],
      optionsEn: <String>[
        'Suggested without being stated directly.',
        'Emphasized explicitly in capital letters.',
        'Hidden behind words with no meaning.',
        'Clearly rejected by everyone.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Beklenti doğrudan yazılmıyor, satır arasında anlaşılıyor.',
      contextEn: 'The expectation is understood between the lines.',
      explanationTr:
          '“Örtük” anlamın doğrudan değil, dolaylı biçimde verilmesidir.',
      explanationEn:
          '“Implicit” describes meaning suggested rather than stated.',
      nearWordsTr: <String>['ima edilen', 'dolaylı'],
      nearWordsEn: <String>['implied', 'indirect'],
    ),
    NearMeaningCard(
      id: 'rebut_claim',
      minimumStage: 7,
      prefixTr: 'Tanık, iddiaya yeni kayıtlarla ',
      targetTr: 'karşı çıktı',
      suffixTr: '.',
      prefixEn: 'The witness ',
      targetEn: 'challenged',
      suffixEn: ' the claim with new records.',
      optionsTr: <String>[
        'İddianın doğruluğuna itiraz edip karşı kanıt sundu.',
        'İddiayı hiçbir inceleme yapmadan benimsedi.',
        'İddianın dilini daha yumuşak hâle getirdi.',
        'İddiayı herkesin önünde tekrar etti.',
      ],
      optionsEn: <String>[
        'Disputed the claim and offered counter-evidence.',
        'Accepted the claim without checking it.',
        'Softened the wording of the claim.',
        'Repeated the claim in front of everyone.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Yeni kayıtlar iddiaya karşı delil olarak sunuluyor.',
      contextEn: 'New records are presented as evidence against the claim.',
      explanationTr: '“Karşı çıkmak” burada gerekçeli bir itiraz anlamındadır.',
      explanationEn: '“Challenge” means to dispute with a reason or evidence.',
      nearWordsTr: <String>['itiraz etmek', 'çürütmeye çalışmak'],
      nearWordsEn: <String>['dispute', 'contest'],
    ),
    NearMeaningCard(
      id: 'coherent_account',
      minimumStage: 7,
      prefixTr: 'Saatler ve belgeler birbiriyle uyuşunca anlatım ',
      targetTr: 'tutarlı',
      suffixTr: ' bulundu.',
      prefixEn: 'Because the times and documents agreed, the account seemed ',
      targetEn: 'consistent',
      suffixEn: '.',
      optionsTr: <String>[
        'Parçaları arasında çelişki bulunmayan.',
        'Her ayrıntısı deneyle kanıtlanmış.',
        'Kısa olduğu için kolay anlaşılan.',
        'Yeni bilgilerle hemen değiştirilen.',
      ],
      optionsEn: <String>[
        'Having parts that do not contradict one another.',
        'Proven by an experiment in every detail.',
        'Easy to understand because it is short.',
        'Quickly changed when new information arrives.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Birden fazla kayıt aynı zaman çizelgesini destekliyor.',
      contextEn: 'Several records support the same timeline.',
      explanationTr:
          '“Tutarlı” parçaların birbirini desteklemesi ve çelişmemesidir.',
      explanationEn:
          '“Consistent” means the parts agree without contradiction.',
      nearWordsTr: <String>['uyumlu', 'çelişkisiz'],
      nearWordsEn: <String>['coherent', 'compatible'],
    ),
    NearMeaningCard(
      id: 'qualify_statement',
      minimumStage: 9,
      prefixTr: 'Araştırmacı, sonucu yalnız bu örneklem için geçerli diyerek ',
      targetTr: 'sınırlandırdı',
      suffixTr: '.',
      prefixEn: 'The researcher ',
      targetEn: 'qualified',
      suffixEn: ' the conclusion as applying only to this sample.',
      optionsTr: <String>[
        'Yargının kapsamına açık bir sınır koydu.',
        'Sonucu bütün durumlar için genelledi.',
        'Araştırmanın sayısal verilerini gizledi.',
        'Sonucu hiçbir gerekçe vermeden geri çekti.',
      ],
      optionsEn: <String>[
        'Placed an explicit limit on the claim’s scope.',
        'Generalized the result to every situation.',
        'Concealed the study’s numerical data.',
        'Withdrew the result without giving a reason.',
      ],
      correctOptionIndex: 0,
      contextTr:
          'Araştırmacı iddianın hangi koşullarda geçerli olduğunu daraltıyor.',
      contextEn: 'The researcher narrows the conditions covered by the claim.',
      explanationTr: '“Sınırlandırmak” burada iddianın kapsamını daraltmaktır.',
      explanationEn: 'To qualify a claim is to state a limit on its scope.',
      nearWordsTr: <String>['koşula bağlamak', 'kapsamını daraltmak'],
      nearWordsEn: <String>['limit', 'restrict'],
    ),
    NearMeaningCard(
      id: 'tentative_plan',
      minimumStage: 9,
      prefixTr: 'Veriler henüz eksik olduğundan bu sonuç ',
      targetTr: 'geçicidir',
      suffixTr: '.',
      prefixEn: 'Because data is still missing, this conclusion is ',
      targetEn: 'tentative',
      suffixEn: '.',
      optionsTr: <String>[
        'Yeni bilgi gelince değişebilecek, kesinleşmemiş.',
        'Her koşulda aynı kalacağı kanıtlanmış.',
        'Başka seçenek kalmadığı için zorunlu.',
        'Geçmişte defalarca doğrulanmış.',
      ],
      optionsEn: <String>[
        'Not final and subject to change with new information.',
        'Proven to stay the same in every circumstance.',
        'Necessary because no other option remains.',
        'Verified many times in the past.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Eksik veri, kararın henüz son hâlini almadığını gösteriyor.',
      contextEn: 'Missing data means the decision has not been finalized.',
      explanationTr:
          '“Geçici” bu bağlamda kesinleşmemiş, değişebilir demektir.',
      explanationEn: 'Here “tentative” means provisional and open to revision.',
      nearWordsTr: <String>['ön karar', 'kesinleşmemiş'],
      nearWordsEn: <String>['provisional', 'preliminary'],
    ),
    NearMeaningCard(
      id: 'corroborate_record',
      minimumStage: 9,
      prefixTr: 'Bağımsız günlükler ilk tanığın saatini ',
      targetTr: 'doğruladı',
      suffixTr: '.',
      prefixEn: 'Independent logs ',
      targetEn: 'corroborated',
      suffixEn: ' the first witness’s timeline.',
      optionsTr: <String>[
        'Ayrı bir kaynaktan destekleyerek daha inandırıcı kıldı.',
        'Tanığın anlatımıyla çelişip geçersiz kıldı.',
        'Tanığın sözlerini aynen kopyalayıp çoğalttı.',
        'Olayın gerçekleştiği zamanı erteledi.',
      ],
      optionsEn: <String>[
        'Supported it with a separate source, increasing confidence.',
        'Contradicted the witness and invalidated the account.',
        'Copied the witness’s exact words several times.',
        'Postponed the time when the event occurred.',
      ],
      correctOptionIndex: 0,
      contextTr: 'İlk anlatım bağımsız kayıtlarla destekleniyor.',
      contextEn: 'A separate record supports the original account.',
      explanationTr:
          '“Doğrulamak” burada bağımsız kanıtla desteklemek anlamındadır.',
      explanationEn:
          'Here “corroborate” means to support with independent evidence.',
      nearWordsTr: <String>['desteklemek', 'teyit etmek'],
      nearWordsEn: <String>['confirm', 'substantiate'],
    ),
    NearMeaningCard(
      id: 'subtle_difference',
      minimumStage: 9,
      prefixTr: 'İki öneri yüzeyde benzer görünse de aralarında ',
      targetTr: 'ince',
      suffixTr: ' bir fark vardı.',
      prefixEn: 'Although the proposals looked alike, there was a ',
      targetEn: 'subtle',
      suffixEn: ' difference between them.',
      optionsTr: <String>[
        'Kolay fark edilmeyen, küçük ama anlamlı.',
        'Gözle görülebilecek kadar büyük ve açık.',
        'Önemsiz olduğu için yok sayılabilecek.',
        'Ölçü aletiyle kolayca sayılabilen.',
      ],
      optionsEn: <String>[
        'Small but meaningful and not immediately obvious.',
        'Large and obvious to anyone who looks.',
        'So unimportant that it can be ignored.',
        'Easy to count with a measuring tool.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Fark küçük; etkisi ancak öneriler dikkatle karşılaştırılınca görülüyor.',
      contextEn: 'The difference appears only after careful comparison.',
      explanationTr: '“İnce fark” az belirgin olsa da anlamı değiştirebilir.',
      explanationEn:
          'A “subtle” difference may be small yet still significant.',
      nearWordsTr: <String>['nüanslı', 'belirsizce seçilen'],
      nearWordsEn: <String>['nuanced', 'delicate'],
    ),
    NearMeaningCard(
      id: 'infer_pattern',
      minimumStage: 9,
      prefixTr: 'Birbirini izleyen ölçümlerdeki artıştan ekip yeni bir eğilim ',
      targetTr: 'çıkardı',
      suffixTr: '.',
      prefixEn: 'From the rising measurements, the team ',
      targetEn: 'inferred',
      suffixEn: ' a new trend.',
      optionsTr: <String>[
        'Doğrudan söylenmeyen bir sonucu kanıtlardan akıl yürüterek buldu.',
        'Yeni eğilimi ölçümlere hiçbir dayanak olmadan ekledi.',
        'Eğilimi başka bir araştırmacıdan aynen aktardı.',
        'Ölçümlerin hepsini tek bir sayıyla değiştirdi.',
      ],
      optionsEn: <String>[
        'Reasoned to a conclusion from evidence without it being stated.',
        'Added a trend without any support from measurements.',
        'Copied the trend directly from another researcher.',
        'Replaced all measurements with a single number.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Eğilim ölçümlerde yazmıyor; artış örüntüsünden çıkarılıyor.',
      contextEn: 'The trend is not stated; it is concluded from a pattern.',
      explanationTr: '“Çıkarmak” burada veriden sonuç çıkarımı yapmaktır.',
      explanationEn:
          'Here “infer” means to conclude from a pattern in evidence.',
      nearWordsTr: <String>['sonuç çıkarmak', 'akıl yürütmek'],
      nearWordsEn: <String>['deduce', 'conclude'],
    ),
    NearMeaningCard(
      id: 'redundant_step',
      minimumStage: 10,
      prefixTr: 'Aynı kontrol iki kez yapıldığından ikinci adım ',
      targetTr: 'gereksizdi',
      suffixTr: '.',
      prefixEn:
          'Since the same check had already been done, the second step was ',
      targetEn: 'redundant',
      suffixEn: '.',
      optionsTr: <String>[
        'Aynı işi yinelediği için ek bir katkı sağlamıyordu.',
        'Sonucu doğrulamak için vazgeçilmezdi.',
        'İlk kontrolden farklı yeni veri üretti.',
        'Yapılması geciktiği için önemli hâle geldi.',
      ],
      optionsEn: <String>[
        'Added nothing because it repeated the same work.',
        'Was essential to verify the outcome.',
        'Produced new data unlike the first check.',
        'Became important because it was delayed.',
      ],
      correctOptionIndex: 0,
      contextTr: 'İkinci adım ilk kontrolü aynen tekrarlıyor.',
      contextEn:
          'The second step repeats the first check without adding value.',
      explanationTr: '“Gereksiz” burada işlevsiz tekrar anlamına gelir.',
      explanationEn:
          '“Redundant” means unnecessary because it repeats existing work.',
      nearWordsTr: <String>['fazladan', 'tekrarlı'],
      nearWordsEn: <String>['superfluous', 'duplicative'],
    ),
    NearMeaningCard(
      id: 'exhaustive_review',
      minimumStage: 10,
      prefixTr: 'Kurul başvurunun her ekini ve dipnotunu kontrol ederek ',
      targetTr: 'kapsamlı',
      suffixTr: ' bir inceleme yaptı.',
      prefixEn: 'The committee checked every attachment and footnote in an ',
      targetEn: 'exhaustive',
      suffixEn: ' review.',
      optionsTr: <String>[
        'Konunun bütün önemli yanlarını içine alan.',
        'Yalnızca ilk sayfaya odaklanan.',
        'Kısa tutulduğu için bazı ekleri atlayan.',
        'Önceden verilmiş kararı tekrar eden.',
      ],
      optionsEn: <String>[
        'Covering all important parts of the subject.',
        'Focusing only on the first page.',
        'Skipping attachments to keep it brief.',
        'Repeating a decision made earlier.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Ekler ve dipnotlar da değerlendirmeye katılıyor.',
      contextEn: 'Attachments and footnotes are included in the review.',
      explanationTr: '“Kapsamlı” inceleme, önemli parçaları dışarıda bırakmaz.',
      explanationEn: 'An “exhaustive” review leaves no important part out.',
      nearWordsTr: <String>['ayrıntılı', 'etraflı'],
      nearWordsEn: <String>['thorough', 'comprehensive'],
    ),
    NearMeaningCard(
      id: 'plausible_alternative',
      minimumStage: 10,
      prefixTr: 'Örneklem küçük olsa da bu açıklama ',
      targetTr: 'makul',
      suffixTr: ' bir olasılık olarak kaldı.',
      prefixEn: 'Although the sample was small, this explanation remained a ',
      targetEn: 'plausible',
      suffixEn: ' possibility.',
      optionsTr: <String>[
        'Mevcut kanıtlarla akla yatkın, fakat kesin olmayan.',
        'Tüm olasılıkları dışlayan tek açıklama.',
        'Ölçümle doğrudan kanıtlanmış kesin sonuç.',
        'Kanıtlarla uyuşmadığı için olanaksız.',
      ],
      optionsEn: <String>[
        'Reasonable from current evidence, but not certain.',
        'The only explanation that rules out every alternative.',
        'A definite result directly proven by measurement.',
        'Impossible because it conflicts with the evidence.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Küçük örneklem kesin hükmü engelliyor.',
      contextEn: 'The small sample prevents a definitive conclusion.',
      explanationTr:
          '“Makul olasılık” güçlü bir ihtimaldir, kesinlik değildir.',
      explanationEn: 'A “plausible possibility” is credible, not certain.',
      nearWordsTr: <String>['olası', 'akla yatkın'],
      nearWordsEn: <String>['credible', 'reasonable'],
    ),
    NearMeaningCard(
      id: 'ambiguous_clause',
      minimumStage: 10,
      prefixTr: 'Zamir hangi kişiyi gösterdiği belli olmayınca madde ',
      targetTr: 'muğlak',
      suffixTr: ' kaldı.',
      prefixEn:
          'Because the pronoun had no clear reference, the clause remained ',
      targetEn: 'ambiguous',
      suffixEn: '.',
      optionsTr: <String>[
        'Birden fazla anlama gelebilecek kadar açık olmayan.',
        'Tek bir anlama gelecek biçimde netleştirilmiş.',
        'Dilbilgisi bakımından tamamen yanlış.',
        'Uzun olduğu için kolayca hatırlanan.',
      ],
      optionsEn: <String>[
        'Unclear enough to allow more than one meaning.',
        'Clarified so it has only one meaning.',
        'Completely incorrect in its grammar.',
        'Easy to remember because it is long.',
      ],
      correctOptionIndex: 0,
      contextTr:
          'Zamirin gönderimi açık değil; okur iki kişiden birini seçebilir.',
      contextEn: 'The pronoun could refer to either of two people.',
      explanationTr: '“Muğlak” birden fazla yoruma açık olmasıdır.',
      explanationEn: '“Ambiguous” means open to more than one interpretation.',
      nearWordsTr: <String>['belirsiz', 'çift anlamlı'],
      nearWordsEn: <String>['unclear', 'equivocal'],
    ),
    NearMeaningCard(
      id: 'qualified_support',
      minimumStage: 10,
      prefixTr: 'Bağımsız ölçümler iddiayı ',
      targetTr: 'destekledi',
      suffixTr: ', ancak tek başına kanıtlamadı.',
      prefixEn: 'Independent measurements ',
      targetEn: 'substantiated',
      suffixEn: ' the claim, but did not prove it on their own.',
      optionsTr: <String>[
        'İddiaya uygun kanıt sağlayıp onu daha inandırıcı kıldı.',
        'İddianın yanlışlığını kesin biçimde gösterdi.',
        'İddiayı araştırmadan kabul etmeye zorladı.',
        'İddiayı bütün koşullardan bağımsız hâle getirdi.',
      ],
      optionsEn: <String>[
        'Provided relevant evidence that made the claim more credible.',
        'Definitively showed that the claim was false.',
        'Forced acceptance of the claim without investigation.',
        'Made the claim independent of all conditions.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Ölçümler iddiayla uyumlu ama kesin kanıt sayılmıyor.',
      contextEn:
          'The measurements align with the claim but are not conclusive.',
      explanationTr:
          '“Desteklemek” iddiayı güçlendirir; “kanıtlamak”tan daha zayıftır.',
      explanationEn:
          '“Substantiate” lends support; it is weaker than proving outright.',
      nearWordsTr: <String>['dayanak sağlamak', 'teyit etmek'],
      nearWordsEn: <String>['support', 'corroborate'],
    ),
    NearMeaningCard(
      id: 'tentative_agreement',
      minimumStage: 10,
      prefixTr: 'Taraflar ayrıntılar netleşene kadar ',
      targetTr: 'koşullu',
      suffixTr: ' bir anlaşma yaptı.',
      prefixEn: 'The parties made a ',
      targetEn: 'conditional',
      suffixEn: ' agreement until the details were settled.',
      optionsTr: <String>[
        'Belirli şartlar gerçekleşirse geçerli olacak.',
        'Hiçbir durumda değiştirilemeyecek.',
        'Taraflardan biri tarafından zaten bozulmuş.',
        'Yalnızca geçmişteki olayları açıklayan.',
      ],
      optionsEn: <String>[
        'Valid only if specified requirements are met.',
        'Impossible to change in any circumstance.',
        'Already broken by one of the parties.',
        'Only describing events from the past.',
      ],
      correctOptionIndex: 0,
      contextTr: 'Anlaşma, ayrıntıların netleşmesi şartına bağlanıyor.',
      contextEn: 'The agreement depends on the details being resolved.',
      explanationTr:
          '“Koşullu” geçerliliğin bir şartın gerçekleşmesine bağlı olmasıdır.',
      explanationEn:
          '“Conditional” means dependent on a specified requirement.',
      nearWordsTr: <String>['şarta bağlı', 'kayıtlı'],
      nearWordsEn: <String>['contingent', 'dependent'],
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
  final List<NearMeaningBoardCard> cards;
  final bool isPractice;
  final int round;

  String get boardSignature {
    final List<String> ids =
        cards.map((NearMeaningBoardCard item) => item.card.id).toList()..sort();
    return ids.join('|');
  }

  static NearMeaningScenario forCampaignLevel(int level) {
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

  static NearMeaningScenario forPracticeRound(int round) {
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

  static NearMeaningScenario _build({
    required List<int> indices,
    required int stage,
    required int round,
    required bool isPractice,
  }) {
    final String mode = isPractice ? 'practice' : 'campaign';
    return NearMeaningScenario(
      stage: stage,
      cards: List<NearMeaningBoardCard>.unmodifiable(
        indices.map((int index) {
          final NearMeaningCard card = _bank[index];
          final List<int> order = List<int>.generate(4, (int option) => option)
            ..shuffle(
              ContentSeed.randomFor(
                gameId: 'near_meaning:$mode:${card.id}:answers',
                level: round,
              ),
            );
          return NearMeaningBoardCard(
            card: card,
            optionOrder: List<int>.unmodifiable(order),
          );
        }),
      ),
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
        throw StateError('No near-meaning board for level $level.');
      }
      final math.Random random = ContentSeed.randomFor(
        gameId: 'near_meaning:campaign',
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
        throw StateError('Near-meaning board repeated at $level.');
      }
      boards.add(List<int>.unmodifiable(selected));
    }
    return List<List<int>>.unmodifiable(boards);
  }

  static List<List<int>> _makePractice() {
    final Set<String> campaign = _campaign.map(_signature).toSet();
    final List<List<int>> candidates =
        _combinations(List<int>.generate(_bank.length, (int index) => index))
            .where((List<int> board) => !campaign.contains(_signature(board)))
            .toList();
    candidates.shuffle(
      ContentSeed.randomFor(gameId: 'near_meaning:practice-order', level: 1),
    );
    if (candidates.length < uniquePracticeRounds) {
      throw StateError('Not enough distinct near-meaning practice boards.');
    }
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
