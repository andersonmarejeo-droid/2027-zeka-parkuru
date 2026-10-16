import 'dart:math' as math;

import '../shared/content_seed.dart';

class ProverbCard {
  const ProverbCard({
    required this.id,
    required this.minimumStage,
    required this.opening,
    required this.ending,
    required this.meaningTr,
    required this.meaningEn,
    required this.contextTr,
    required this.contextEn,
  });

  final String id;
  final int minimumStage;
  final String opening;
  final String ending;
  final String meaningTr;
  final String meaningEn;
  final String contextTr;
  final String contextEn;

  String get fullText => '$opening $ending';
}

/// A four-proverb completion board. Each selected ending belongs to exactly
/// one opening; seed-based ordering keeps QA and competition layouts stable.
class ProverbFinishScenario {
  const ProverbFinishScenario({
    required this.stage,
    required this.cards,
    required this.answerOrder,
    required this.isPractice,
    required this.round,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;

  static const List<ProverbCard> _bank = <ProverbCard>[
    ProverbCard(
      id: 'drop_lake',
      minimumStage: 1,
      opening: 'Damlaya damlaya',
      ending: 'göl olur.',
      meaningTr: 'Küçük ve düzenli katkılar zamanla büyük sonuca ulaşır.',
      meaningEn: 'Small, steady contributions can grow into a large result.',
      contextTr:
          'Her hafta az da olsa birikim yapan Ece, yıl sonunda tatilini ödedi.',
      contextEn:
          'Ece saved a little each week and paid for a trip by year-end.',
    ),
    ProverbCard(
      id: 'save_for_later',
      minimumStage: 1,
      opening: 'Sakla samanı',
      ending: 'gelir zamanı.',
      meaningTr: 'Önemsiz görünen şeyler ileride işe yarayabilir.',
      meaningEn: 'Something that seems unimportant may be useful later.',
      contextTr:
          'Mert eski yedek parçaları atmadı; arıza çıkınca tamir edebildi.',
      contextEn:
          'Mert kept spare parts and used them when a repair was needed.',
    ),
    ProverbCard(
      id: 'tree_young',
      minimumStage: 1,
      opening: 'Ağaç yaşken',
      ending: 'eğilir.',
      meaningTr: 'Alışkanlık ve eğitim küçük yaşta daha kolay kazanılır.',
      meaningEn: 'Habits and learning are easier to shape early in life.',
      contextTr: 'Duru küçükken düzenli kitap okuma alışkanlığı kazandı.',
      contextEn: 'Duru built a regular reading habit while she was young.',
    ),
    ProverbCard(
      id: 'working_iron',
      minimumStage: 1,
      opening: 'İşleyen demir',
      ending: 'ışıldar.',
      meaningTr: 'Çalışan ve üretken kalan kişi becerisini canlı tutar.',
      meaningEn: 'A person who keeps working and learning stays capable.',
      contextTr: 'Emekli olduktan sonra da atölyesinde üretmeye devam etti.',
      contextEn:
          'After retiring, she continued creating things in her workshop.',
    ),
    ProverbCard(
      id: 'black_day_coin',
      minimumStage: 1,
      opening: 'Ak akçe',
      ending: 'kara gün içindir.',
      meaningTr: 'Birikim, zor zamanlarda güvence sağlar.',
      meaningEn: 'Savings provide security when difficult times arrive.',
      contextTr: 'Beklenmedik masraf çıkınca kenara koyduğu para işe yaradı.',
      contextEn: 'Her savings helped when an unexpected expense came up.',
    ),
    ProverbCard(
      id: 'two_hands',
      minimumStage: 1,
      opening: 'Bir elin nesi var,',
      ending: 'iki elin sesi var.',
      meaningTr: 'Birlikte çalışan insanlar daha büyük işler başarabilir.',
      meaningEn: 'People can accomplish more when they work together.',
      contextTr: 'Mahalleli el ele verince parkı bir günde temizledi.',
      contextEn:
          'The neighbors cleaned the park in one day by working together.',
    ),
    ProverbCard(
      id: 'friend_hard_day',
      minimumStage: 3,
      opening: 'Dost kara günde',
      ending: 'belli olur.',
      meaningTr: 'Gerçek dost, insanın zor zamanında yanında olandır.',
      meaningEn: 'A true friend is revealed by being there in hard times.',
      contextTr: 'Herkes çekildiğinde Zeynep arkadaşının yanında kaldı.',
      contextEn: 'Zeynep stayed by her friend when everyone else left.',
    ),
    ProverbCard(
      id: 'rose_thorns',
      minimumStage: 3,
      opening: 'Gülü seven',
      ending: 'dikenine katlanır.',
      meaningTr: 'Değer verilen bir şeyin güçlükleri de göze alınır.',
      meaningEn:
          'Choosing something worthwhile can mean accepting its difficulties.',
      contextTr:
          'Dağ yürüyüşünü sevdiği için uzun ve yorucu rotaya da razı oldu.',
      contextEn:
          'Because she loved hiking, she accepted the long, difficult route.',
    ),
    ProverbCard(
      id: 'reap_what_sow',
      minimumStage: 3,
      opening: 'Ne ekersen',
      ending: 'onu biçersin.',
      meaningTr: 'İnsan çoğunlukla yaptıklarının karşılığını görür.',
      meaningEn: 'People generally face the consequences of their own actions.',
      contextTr: 'Düzenli çalışmasının karşılığını sınav sonucunda aldı.',
      contextEn: 'Her exam result reflected the steady work she had put in.',
    ),
    ProverbCard(
      id: 'neighbor_ash',
      minimumStage: 3,
      opening: 'Komşu komşunun',
      ending: 'külüne muhtaçtır.',
      meaningTr: 'İnsanlar yakın çevresindekilerin küçük yardımlarına bile ihtiyaç duyar.',
      meaningEn: 'People rely on neighbors even for small acts of help.',
      contextTr: 'Şeker bitince bir fincan çay için yan komşusuna uğradı.',
      contextEn: 'When she ran out of sugar, she borrowed some from next door.',
    ),
    ProverbCard(
      id: 'measure_your_cloth',
      minimumStage: 5,
      opening: 'Ayağını yorganına',
      ending: 'göre uzat.',
      meaningTr: 'Harcamalarını olanaklarına göre ayarlamak gerekir.',
      meaningEn: 'Spending should stay within the limits of your means.',
      contextTr: 'Geliri azaldığında Deniz daha uygun bir ev seçti.',
      contextEn: 'When her income fell, Deniz chose a more affordable home.',
    ),
    ProverbCard(
      id: 'today_work',
      minimumStage: 5,
      opening: 'Bugünün işini',
      ending: 'yarına bırakma.',
      meaningTr: 'Yapılması gereken işi gereksiz yere ertelememek gerekir.',
      meaningEn: 'Necessary work should not be delayed without a reason.',
      contextTr: 'Raporunu son güne bırakmadı; akşam erkenden tamamladı.',
      contextEn: 'She finished the report early instead of leaving it to the deadline.',
    ),
    ProverbCard(
      id: 'market_calculation',
      minimumStage: 5,
      opening: 'Evdeki hesap',
      ending: 'çarşıya uymaz.',
      meaningTr: 'Gerçek koşullar, önceden yapılan planı değiştirebilir.',
      meaningEn: 'Real conditions can upset a plan made in advance.',
      contextTr:
          'Tadilat bütçesi, duvar açılınca çıkan sorunlar yüzünden aşıldı.',
      contextEn: 'The renovation budget grew after hidden problems were found.',
    ),
    ProverbCard(
      id: 'carried_water',
      minimumStage: 5,
      opening: 'Taşıma suyla',
      ending: 'değirmen dönmez.',
      meaningTr: 'Geçici destek, sürekli ihtiyacı tek başına karşılayamaz.',
      meaningEn: 'A temporary supply cannot sustain an ongoing need by itself.',
      contextTr: 'Sistemi her gün elle onarmak yerine kalıcı çözüm kurdu.',
      contextEn:
          'He built a lasting fix instead of patching the system each day.',
    ),
    ProverbCard(
      id: 'fish_head',
      minimumStage: 7,
      opening: 'Balık baştan',
      ending: 'kokar.',
      meaningTr: 'Bir kurumdaki bozulma çoğu zaman yöneticilerden başlar.',
      meaningEn: 'Corruption in an organization often starts at the top.',
      contextTr: 'Yöneticiler kurala uymayınca ekipte de düzensizlik başladı.',
      contextEn:
          'When managers ignored the rules, disorder spread through the team.',
    ),
    ProverbCard(
      id: 'visible_village',
      minimumStage: 7,
      opening: 'Görünen köy',
      ending: 'kılavuz istemez.',
      meaningTr:
          'Açıkça ortada olan bir durumu anlamak için özel açıklama gerekmez.',
      meaningEn: 'A plainly visible situation needs no special explanation.',
      contextTr:
          'Duman ve alarm varken binada yangın olduğunu anlamak zor değildi.',
      contextEn: 'With smoke and alarms, it was obvious there was a fire.',
    ),
    ProverbCard(
      id: 'thursday_wednesday',
      minimumStage: 7,
      opening: 'Perşembenin gelişi',
      ending: 'çarşambadan bellidir.',
      meaningTr:
          'Bir işin nasıl sonuçlanacağı, önceki işaretlerden anlaşılabilir.',
      meaningEn: 'Early signs can reveal how something is likely to turn out.',
      contextTr:
          'Provalar aksayınca gösterinin yetişmeyeceği önceden belliydi.',
      contextEn:
          'After repeated missed rehearsals, the show was clearly at risk.',
    ),
    ProverbCard(
      id: 'minaret_cover',
      minimumStage: 7,
      opening: 'Minareyi çalan',
      ending: 'kılıfını hazırlar.',
      meaningTr: 'Kötü niyetli kişi, yapacağı yanlışa önceden bahane hazırlar.',
      meaningEn:
          'Someone planning wrongdoing may prepare an excuse in advance.',
      contextTr:
          'Sahte faturayı kesmeden önce denetim için bir hikâye uydurdu.',
      contextEn:
          'Before submitting a false bill, he invented a story for auditors.',
    ),
    ProverbCard(
      id: 'haste_devil',
      minimumStage: 9,
      opening: 'Acele işe',
      ending: 'şeytan karışır.',
      meaningTr: 'Aşırı telaş, yanlış ve eksik iş yapılmasına yol açabilir.',
      meaningEn: 'Excessive haste can lead to mistakes and unfinished work.',
      contextTr: 'Kontrol etmeden gönderdiği dosyada önemli bir sayfa eksikti.',
      contextEn:
          'The file she sent without checking was missing an important page.',
    ),
    ProverbCard(
      id: 'snake_drowning',
      minimumStage: 9,
      opening: 'Denize düşen',
      ending: 'yılana sarılır.',
      meaningTr: 'Çok çaresiz kalan kişi normalde kaçınacağı şeye yönelebilir.',
      meaningEn: 'In desperation, a person may turn to an option they would usually avoid.',
      contextTr: 'Başka desteği kalmayınca güvenmediği birinden borç istedi.',
      contextEn: 'With no other support left, he asked an untrusted person for a loan.',
    ),
    ProverbCard(
      id: 'grapes_dark',
      minimumStage: 9,
      opening: 'Üzüm üzüme baka baka',
      ending: 'kararır.',
      meaningTr: 'İnsan, sürekli birlikte olduğu kişilerin davranışlarından etkilenir.',
      meaningEn:
          'People are influenced by those they spend a lot of time with.',
      contextTr:
          'Yeni ekipte herkes erken geldiği için o da bu alışkanlığı edindi.',
      contextEn: 'Because the new team arrived early, he gradually adopted the habit too.',
    ),
    ProverbCard(
      id: 'liars_candle',
      minimumStage: 9,
      opening: 'Yalancının mumu',
      ending: 'yatsıya kadar yanar.',
      meaningTr: 'Yalan ve aldatma uzun süre gizli kalamaz.',
      meaningEn: 'A lie or deception cannot stay hidden for long.',
      contextTr: 'Söylediği tarih kayıtlarla uyuşmayınca gerçeği anlaşıldı.',
      contextEn: 'The records contradicted his date, and the truth came out.',
    ),
    ProverbCard(
      id: 'hand_surpasses_hand',
      minimumStage: 10,
      opening: 'El elden',
      ending: 'üstündür.',
      meaningTr:
          'Bir başkasının becerisi, insanın kendi becerisinden üstün olabilir.',
      meaningEn: 'Someone else may have greater skill or knowledge than you.',
      contextTr: 'Usta aşçı, onun tarifine küçük bir dokunuşla bambaşka bir tat verdi.',
      contextEn:
          'A skilled chef improved her recipe with one small adjustment.',
    ),
    ProverbCard(
      id: 'tongue_wound',
      minimumStage: 10,
      opening: 'El yarası geçer,',
      ending: 'dil yarası geçmez.',
      meaningTr: 'Kırıcı sözlerin bıraktığı iz, bedensel bir yaradan daha uzun sürebilir.',
      meaningEn:
          'A hurtful remark can leave a longer-lasting wound than an injury.',
      contextTr: 'Tartışmada duyduğu ağır sözleri yıllar sonra bile unutamadı.',
      contextEn: 'Years later, she still remembered the cruel words from the argument.',
    ),
    ProverbCard(
      id: 'sweet_tongue',
      minimumStage: 10,
      opening: 'Tatlı dil',
      ending: 'yılanı deliğinden çıkarır.',
      meaningTr:
          'Nazik ve ikna edici konuşma, zor kişileri bile yumuşatabilir.',
      meaningEn: 'Kind, persuasive speech can soften even a difficult person.',
      contextTr: 'Sert tepki vermek yerine sakin konuşup komşusunu ikna etti.',
      contextEn: 'Instead of reacting harshly, he spoke calmly and persuaded his neighbor.',
    ),
    ProverbCard(
      id: 'sharp_vinegar',
      minimumStage: 10,
      opening: 'Keskin sirke',
      ending: 'küpüne zarar.',
      meaningTr: 'Aşırı öfke, en çok öfkelenen kişiye zarar verir.',
      meaningEn: 'Excessive anger harms the angry person most of all.',
      contextTr: 'Öfkeyle gönderdiği mesaj yüzünden iş arkadaşını kaybetti.',
      contextEn: 'The angry message cost him a valued working relationship.',
    ),
    ProverbCard(
      id: 'turn_back_profit',
      minimumStage: 10,
      opening: 'Zararın neresinden dönülse',
      ending: 'kârdır.',
      meaningTr: 'Yanlış giden bir işi ne kadar erken bırakmak, zararı o kadar azaltır.',
      meaningEn: 'Stopping a failing course earlier reduces the loss.',
      contextTr: 'Daha fazla para harcamadan hatalı yatırımı sonlandırdı.',
      contextEn: 'She ended a failing investment before losing more money.',
    ),
    ProverbCard(
      id: 'cheese_ship',
      minimumStage: 10,
      opening: 'Lafla peynir',
      ending: 'gemisi yürümez.',
      meaningTr: 'Yalnızca konuşmak, emek ve eylem gerektiren işi tamamlamaz.',
      meaningEn: 'Talk alone cannot finish work that requires action.',
      contextTr: 'Planı anlatmakla yetinmeyip ilk prototipi de hazırladı.',
      contextEn:
          'He did more than discuss the plan: he built the first prototype.',
    ),
    ProverbCard(
      id: 'caravan_road',
      minimumStage: 10,
      opening: 'Kervan yolda',
      ending: 'düzülür.',
      meaningTr:
          'Bazı hazırlık ve düzenlemeler işe başladıktan sonra yapılabilir.',
      meaningEn:
          'Some planning and adjustments can happen after a project starts.',
      contextTr: 'İlk sürümü yayımladı, sonra kullanıcı geri bildirimleriyle geliştirdi.',
      contextEn:
          'They released a first version and refined it with user feedback.',
    ),
    ProverbCard(
      id: 'friend_head_enemy_foot',
      minimumStage: 10,
      opening: 'Dost başa, düşman',
      ending: 'ayağa bakar.',
      meaningTr:
          'Dost insanın değerine; düşman ise kusur ve eksiklerine odaklanır.',
      meaningEn: 'A friend values you; an enemy looks for your flaws.',
      contextTr:
          'Arkadaşı başarısını kutladı; rakibi ise küçük hatasına takıldı.',
      contextEn: 'Her friend celebrated the achievement; her rival focused on a small flaw.',
    ),
    ProverbCard(
      id: 'aba_rain', minimumStage: 10,
      opening: 'Abanın kadri', ending: 'yağmurda bilinir.',
      meaningTr: 'Bir şeyin değeri, ihtiyaç duyulduğunda anlaşılır.',
      meaningEn: 'The value of something becomes clear when it is needed.',
      contextTr: 'Yağmur bastırınca yanında taşıdığı eski yağmurluğa sevindi.',
      contextEn: 'When rain began, she was glad she had brought her old raincoat.',
    ),
    ProverbCard(
      id: 'bitter_eggplant', minimumStage: 10,
      opening: 'Acı patlıcanı', ending: 'kırağı çalmaz.',
      meaningTr: 'Güçlüklere alışmış kişi, benzer sıkıntılardan kolay etkilenmez.',
      meaningEn: 'A person accustomed to hardship is less shaken by similar troubles.',
      contextTr: 'Zorlu kışlara alışık çiftçi, erken soğukta telaşa kapılmadı.',
      contextEn: 'The farmer, used to harsh winters, stayed calm when the cold came early.',
    ),
    ProverbCard(
      id: 'goat_kid', minimumStage: 11,
      opening: 'Ağaca çıkan keçinin, dala bakan', ending: 'oğlağı olur.',
      meaningTr: 'Büyüklerin davranışları çocuklara örnek olur.',
      meaningEn: 'Children often imitate the behavior of their elders.',
      contextTr: 'Babası kitap okudukça oğlu da eline bir kitap aldı.',
      contextEn: 'Whenever his father read, his son picked up a book too.',
    ),
    ProverbCard(
      id: 'advice_not_needed', minimumStage: 11,
      opening: 'Arife', ending: 'tarif gerekmez.',
      meaningTr: 'Bir işi iyi bilen kişiye uzun uzun açıklama yapmaya gerek yoktur.',
      meaningEn: 'An expert does not need lengthy instructions about a familiar task.',
      contextTr: 'Yıllardır bu işi yapan ustaya yalnızca malzemeleri bıraktılar.',
      contextEn: 'They left the materials for the craftsperson who had done this for years.',
    ),
    ProverbCard(
      id: 'arrow_returns_not', minimumStage: 11,
      opening: 'Atılan ok', ending: 'geri dönmez.',
      meaningTr: 'Söylenen sözün veya yapılan işin sonuçları geri alınamaz.',
      meaningEn: 'The consequences of an action or spoken word cannot be undone.',
      contextTr: 'Mesajı göndermeden önce bir kez daha okuyup yanlış anlaşılmayı önledi.',
      contextEn: 'She reread the message before sending it to avoid a lasting misunderstanding.',
    ),
    ProverbCard(
      id: 'hunter_hunted', minimumStage: 11,
      opening: 'Ava giden', ending: 'avlanır.',
      meaningTr: 'Başkasına zarar vermek isteyen kişi kendi tuzağına düşebilir.',
      meaningEn: 'Someone trying to harm another may fall into their own trap.',
      contextTr: 'Rakibine kurduğu oyunu fark etmeyince kendi planı bozuldu.',
      contextEn: 'His plan backfired when he failed to notice the trap he had set for a rival.',
    ),
    ProverbCard(
      id: 'crooked_chimney', minimumStage: 12,
      opening: 'Baca eğri de olsa', ending: 'dumanı doğru çıkar.',
      meaningTr: 'Kusurlu görünen şeylerden de doğru ve iyi sonuç çıkabilir.',
      meaningEn: 'Good and honest results can come from an imperfect situation.',
      contextTr: 'Eski atölye bakımsızdı ama içindeki usta çok iyi işler çıkarıyordu.',
      contextEn: 'The old workshop looked worn, yet its craftsperson produced excellent work.',
    ),
    ProverbCard(
      id: 'saying_honey', minimumStage: 12,
      opening: 'Bal bal demekle', ending: 'ağız tatlanmaz.',
      meaningTr: 'Bir şeyi istemek ya da anlatmak, onu gerçekleştirmeye yetmez.',
      meaningEn: 'Talking about a goal does not accomplish it by itself.',
      contextTr: 'Sadece proje konuşmak yerine işe koyulup ilk adımı attılar.',
      contextEn: 'Instead of only discussing the project, they got started on the first step.',
    ),
    ProverbCard(
      id: 'two_roosters', minimumStage: 12,
      opening: 'Bir çöplükte iki horoz', ending: 'ötmez.',
      meaningTr: 'Aynı yerde iki kişinin de baş olma isteği çatışma doğurur.',
      meaningEn: 'Two people competing to lead the same group can create conflict.',
      contextTr: 'İki yönetici de son kararı vermek isteyince ekip ilerleyemedi.',
      contextEn: 'The team stalled when both managers insisted on having the final say.',
    ),
    ProverbCard(
      id: 'today_chicken', minimumStage: 12,
      opening: 'Bugünkü tavuk yarınki kazdan', ending: 'iyidir.',
      meaningTr: 'Kesin olan küçük kazanç, belirsiz büyük kazançtan yeğdir.',
      meaningEn: 'A certain modest gain can be better than a larger uncertain one.',
      contextTr: 'Riskli teklifi reddedip elindeki garantili işi kabul etti.',
      contextEn: 'She chose the guaranteed job instead of the risky offer.',
    ),
    ProverbCard(
      id: 'habit_remains', minimumStage: 13,
      opening: 'Can çıkmayınca', ending: 'huy çıkmaz.',
      meaningTr: 'Kişinin köklü alışkanlıklarını değiştirmesi çok zordur.',
      meaningEn: 'Deep-rooted habits are very difficult to change.',
      contextTr: 'Her seferinde geç kalmamaya söz verse de eski alışkanlığını sürdürdü.',
      contextEn: 'Though he promised to be on time, his old habit persisted.',
    ),
    ProverbCard(
      id: 'nail_nail', minimumStage: 13,
      opening: 'Çivi çiviyi', ending: 'söker.',
      meaningTr: 'Bir sıkıntı bazen benzer başka bir şeyle giderilebilir.',
      meaningEn: 'One difficulty can sometimes be eased by something similar.',
      contextTr: 'Eski aracın parçası bulunmayınca aynı modelden sağlam bir parça kullandı.',
      contextEn: 'When the exact part was unavailable, he used a sound part from the same model.',
    ),
    ProverbCard(
      id: 'mountain_path', minimumStage: 13,
      opening: 'Dağ ne kadar yüce olsa', ending: 'yol üstünden aşar.',
      meaningTr: 'Aşılmaz görünen engellerin de bir çözüm yolu bulunabilir.',
      meaningEn: 'Even an imposing obstacle may have a way through it.',
      contextTr: 'Sorun karmaşık görünüyordu; ekip sonunda uygulanabilir bir yol buldu.',
      contextEn: 'The problem looked daunting, but the team eventually found a workable route.',
    ),
    ProverbCard(
      id: 'mountain_people_meet', minimumStage: 13,
      opening: 'Dağ dağa kavuşmaz, insan insana', ending: 'kavuşur.',
      meaningTr: 'İnsanlar zaman içinde yeniden karşılaşabilir.',
      meaningEn: 'People may meet again, even after a long separation.',
      contextTr: 'Yıllar sonra başka bir şehirde eski sınıf arkadaşıyla karşılaştı.',
      contextEn: 'Years later, she ran into an old classmate in another city.',
    ),
    ProverbCard(
      id: 'trouble_remedy', minimumStage: 14,
      opening: 'Derdini söylemeyen', ending: 'derman bulamaz.',
      meaningTr: 'Yardım isteyen kişi sıkıntısını açıkça anlatmalıdır.',
      meaningEn: 'People must explain their trouble if they hope to get help.',
      contextTr: 'Sorunu saklamak yerine öğretmenine anlatınca destek alabildi.',
      contextEn: 'She received support after explaining the problem to her teacher.',
    ),
    ProverbCard(
      id: 'thought_speech', minimumStage: 14,
      opening: 'Dervişin fikri neyse', ending: 'zikri de odur.',
      meaningTr: 'İnsan zihnini meşgul eden şeyden sık sık söz eder.',
      meaningEn: 'People often talk about whatever occupies their thoughts.',
      contextTr: 'Yeni açacağı dükkânı her sohbetinde anlatıyordu.',
      contextEn: 'She brought up the shop she hoped to open in nearly every conversation.',
    ),
    ProverbCard(
      id: 'wrongdoer_answer', minimumStage: 14,
      opening: 'Dinsizin hakkından', ending: 'imansız gelir.',
      meaningTr: 'Kötü niyetli kişiyi bazen ancak onun yöntemini bilen biri durdurabilir.',
      meaningEn: 'Sometimes only someone who understands a wrongdoer can stop them.',
      contextTr: 'Hile yapan satıcıyı, aynı yöntemleri bilen denetçi ortaya çıkardı.',
      contextEn: 'An inspector familiar with the scheme exposed the dishonest seller.',
    ),
    ProverbCard(
      id: 'fallen_no_friend', minimumStage: 14,
      opening: 'Düşenin', ending: 'dostu olmaz.',
      meaningTr: 'İnsan zor duruma düşünce çevresinden destek bulamayabilir.',
      meaningEn: 'People may find that support disappears when they fall on hard times.',
      contextTr: 'İşi bozulunca onu arayanların çoğu ortadan kayboldu.',
      contextEn: 'When his business failed, most of the people who called him disappeared.',
    ),
    ProverbCard(
      id: 'borrowed_mount', minimumStage: 15,
      opening: 'El atına binen', ending: 'tez iner.',
      meaningTr: 'Başkalarının olana güvenen kişi, o olana her zaman sahip olamaz.',
      meaningEn: 'Someone relying on another person’s property cannot count on it forever.',
      contextTr: 'Başkasının aracına güvenmek yerine kendi ulaşım planını yaptı.',
      contextEn: 'He made his own travel plan instead of relying on someone else’s car.',
    ),
    ProverbCard(
      id: 'neighbor_donkey', minimumStage: 15,
      opening: 'El elin eşeğini', ending: 'türkü çağırarak arar.',
      meaningTr: 'Başkalarının işi, insanın kendi işi kadar içten takip edilmez.',
      meaningEn: 'People rarely pursue someone else’s affairs with the same care as their own.',
      contextTr: 'Danışman raporu geciktirince, kendi ekibinin takibini kendisi üstlendi.',
      contextEn: 'When the consultant delayed the report, she followed it up herself.',
    ),
    ProverbCard(
      id: 'guarded_eye', minimumStage: 15,
      opening: 'Esirgenen göze', ending: 'çöp batar.',
      meaningTr: 'Aşırı korumacılık, önlenmek istenen zarara yol açabilir.',
      meaningEn: 'Overprotection can cause the very harm it is meant to prevent.',
      contextTr: 'Çocuğu hiç deneme yapmasın diye engelleyince özgüven kazanamadı.',
      contextEn: 'By preventing every attempt, they kept the child from gaining confidence.',
    ),
    ProverbCard(
      id: 'flesh_nail', minimumStage: 15,
      opening: 'Et tırnaktan', ending: 'ayrılmaz.',
      meaningTr: 'Yakın akrabalar veya çok bağlı kişiler kolayca birbirinden kopmaz.',
      meaningEn: 'Close family or deeply bonded people are not easily separated.',
      contextTr: 'Uzun süredir küs olsalar da zor günde birbirlerine koştular.',
      contextEn: 'Though estranged for years, they came to each other’s aid in a crisis.',
    ),
    ProverbCard(
      id: 'sun_clay', minimumStage: 16,
      opening: 'Güneş', ending: 'balçıkla sıvanmaz.',
      meaningTr: 'Açık bir gerçeği saklamak veya yok saymak mümkün değildir.',
      meaningEn: 'An obvious truth cannot be hidden or denied.',
      contextTr: 'Kayıtlar ortadayken yapılan hata inkâr edilemedi.',
      contextEn: 'With the records in plain view, the mistake could not be denied.',
    ),
    ProverbCard(
      id: 'rooster_own_yard', minimumStage: 16,
      opening: 'Her horoz kendi çöplüğünde', ending: 'öter.',
      meaningTr: 'İnsan, kendini güçlü hissettiği çevrede daha rahat davranır.',
      meaningEn: 'People act more confidently in surroundings where they feel in control.',
      contextTr: 'Yeni ortamda sessizdi, kendi mahallesinde ise herkesi tanıyordu.',
      contextEn: 'He was quiet in the new place but knew everyone in his own neighborhood.',
    ),
    ProverbCard(
      id: 'yogurt_way', minimumStage: 16,
      opening: 'Her yiğidin bir yoğurt', ending: 'yiyişi vardır.',
      meaningTr: 'Herkesin bir işi yapma ve yaşama biçimi kendine özgüdür.',
      meaningEn: 'Everyone has their own way of doing things.',
      contextTr: 'İki usta aynı işi farklı yöntemlerle başarıyla tamamladı.',
      contextEn: 'The two craftspeople completed the same task successfully in different ways.',
    ),
    ProverbCard(
      id: 'unreachable_liver', minimumStage: 16,
      opening: 'Kedi uzanamadığı ciğere', ending: 'mundar der.',
      meaningTr: 'Elde edemediği şeyi küçümseyen kişi için söylenir.',
      meaningEn: 'Said of someone who belittles what they cannot obtain.',
      contextTr: 'Seçilemeyince ödülün zaten değersiz olduğunu söylemeye başladı.',
      contextEn: 'After not being selected, he began saying the prize was worthless anyway.',
    ),
    ProverbCard(
      id: 'goose_chicken', minimumStage: 17,
      opening: 'Kaz gelen yerden', ending: 'tavuk esirgenmez.',
      meaningTr: 'Büyük yarar beklenen yere küçük katkı vermekten kaçınılmaz.',
      meaningEn: 'A small investment is worthwhile where a greater benefit is expected.',
      contextTr: 'Önemli müşteriye daha iyi hizmet sunmak için ek mesai ayırdılar.',
      contextEn: 'They put in extra effort to serve an important client well.',
    ),
    ProverbCard(
      id: 'goat_abdurrahman', minimumStage: 17,
      opening: 'Koyunun olmadığı yerde keçiye', ending: 'Abdurrahman Çelebi derler.',
      meaningTr: 'Daha iyisi bulunmadığında eldeki kişi ya da şey değerli sayılır.',
      meaningEn: 'When nothing better is available, what remains is treated as valuable.',
      contextTr: 'Asıl konuşmacı gelemeyince yedek sunucu bir anda başrole çıktı.',
      contextEn: 'When the main speaker could not come, the substitute suddenly took center stage.',
    ),
    ProverbCard(
      id: 'sleeping_blind', minimumStage: 17,
      opening: 'Körle yatan', ending: 'şaşı kalkar.',
      meaningTr: 'Kişi, sürekli birlikte olduğu insanların alışkanlıklarından etkilenir.',
      meaningEn: 'People pick up habits from those with whom they spend time.',
      contextTr: 'Düzensiz ekiple çalışınca o da işlerini son dakikaya bırakmaya başladı.',
      contextEn: 'Working with a disorganized team, she also began leaving tasks until the last minute.',
    ),
    ProverbCard(
      id: 'heavy_pot', minimumStage: 17,
      opening: 'Ağır kazan', ending: 'geç kaynar.',
      meaningTr: 'Ağır davranan kişi bir işe geç başlasa da uzun süre sebat edebilir.',
      meaningEn: 'A slow starter may take time to act but can remain steady once engaged.',
      contextTr: 'Başta sessiz kalan ekip üyesi, çalışmaya başlayınca işi dikkatle tamamladı.',
      contextEn: 'The quiet team member took time to begin, then completed the work with care.',
    ),
    ProverbCard(
      id: 'fear_fate', minimumStage: 18,
      opening: 'Korkunun ecele', ending: 'faydası yoktur.',
      meaningTr: 'Kaçınılmaz bir sonuçtan korkmak onu değiştirmez.',
      meaningEn: 'Fearing an unavoidable outcome does not change it.',
      contextTr: 'Sonucu ertelemek yerine doktor randevusuna gidip gerekeni öğrendi.',
      contextEn: 'Instead of delaying, she went to the appointment and learned what to do.',
    ),
    ProverbCard(
      id: 'bear_uncle', minimumStage: 18,
      opening: 'Köprüyü geçene kadar ayıya', ending: 'dayı derler.',
      meaningTr: 'İnsan, işi bitene kadar çıkarı olan kişiye geçici olarak hoş görünür.',
      meaningEn: 'Someone may flatter a person temporarily until their own need is met.',
      contextTr: 'İzni çıkana kadar yöneticiyi övdü, sonra bir daha uğramadı.',
      contextEn: 'He praised the manager until his permit was approved, then stopped visiting.',
    ),
    ProverbCard(
      id: 'life_fragment', minimumStage: 18,
      opening: 'Mal canın', ending: 'yongasıdır.',
      meaningTr: 'İnsan malını ve birikimini kendi yaşamının değerli bir parçası sayar.',
      meaningEn: 'People regard their possessions and savings as a precious part of life.',
      contextTr: 'Yıllarca biriktirdiği aracı dikkatsizce kullanmaktan kaçındı.',
      contextEn: 'He was careful with the car he had saved for over many years.',
    ),
    ProverbCard(
      id: 'candle_at_foot', minimumStage: 18,
      opening: 'Mum dibine', ending: 'ışık vermez.',
      meaningTr: 'Kişi, başkalarına yararlı olurken en yakınındakileri ihmal edebilir.',
      meaningEn: 'Someone may help others while neglecting those closest to them.',
      contextTr: 'Herkese destek oldu ama ailesiyle geçirecek zaman ayıramadı.',
      contextEn: 'She supported everyone but made little time for her own family.',
    ),
    ProverbCard(
      id: 'anger_loss', minimumStage: 19,
      opening: 'Öfkeyle kalkan', ending: 'zararla oturur.',
      meaningTr: 'Öfke anında verilen kararlar çoğu zaman pişmanlık doğurur.',
      meaningEn: 'Decisions made in anger often lead to regret.',
      contextTr: 'Sinirle istifa mesajı yazdı; göndermeden bekleyip vazgeçti.',
      contextEn: 'He drafted a resignation in anger, waited, and decided not to send it.',
    ),
    ProverbCard(
      id: 'wind_storm', minimumStage: 19,
      opening: 'Rüzgâr eken', ending: 'fırtına biçer.',
      meaningTr: 'Kışkırtıcı ve yıkıcı davranışların daha ağır sonuçları olur.',
      meaningEn: 'Provocative, destructive actions can bring even harsher consequences.',
      contextTr: 'Rakiplerini sürekli hedef gösterince tartışma kısa sürede büyüdü.',
      contextEn: 'After repeatedly targeting rivals, the dispute quickly escalated.',
    ),
    ProverbCard(
      id: 'water_jug', minimumStage: 19,
      opening: 'Su testisi', ending: 'su yolunda kırılır.',
      meaningTr: 'Kişi, sürekli içinde bulunduğu işin veya ortamın tehlikesiyle karşılaşabilir.',
      meaningEn: 'A person may eventually face the risks of the work or environment they frequent.',
      contextTr: 'Uyarılara rağmen güvenliksiz çalışan işçi sonunda kaza geçirdi.',
      contextEn: 'Despite warnings, the worker who ignored safety eventually had an accident.',
    ),
    ProverbCard(
      id: 'field_trace', minimumStage: 19,
      opening: 'Tarlada izi olmayanın', ending: 'harmanda yüzü olmaz.',
      meaningTr: 'Emek vermeyen kişi, emeğin sonucunu bekleyemez.',
      meaningEn: 'A person who puts in no effort cannot expect its rewards.',
      contextTr: 'Dönem boyunca çalışmayan öğrenci yüksek not beklememesi gerektiğini anladı.',
      contextEn: 'The student realized that a high grade could not be expected without studying.',
    ),
    ProverbCard(
      id: 'unexpected_stone', minimumStage: 20,
      opening: 'Ummadığın taş', ending: 'baş yarar.',
      meaningTr: 'Küçük veya önemsiz görülen biri beklenmedik biçimde etkili olabilir.',
      meaningEn: 'Someone underestimated may prove unexpectedly capable.',
      contextTr: 'Sessiz stajyer, yarışmanın en iyi çözümünü ortaya koydu.',
      contextEn: 'The quiet intern produced the strongest solution in the competition.',
    ),
    ProverbCard(
      id: 'snake_head', minimumStage: 20,
      opening: 'Yılanın başı küçükken', ending: 'ezilir.',
      meaningTr: 'Büyümeden fark edilen bir sorun erken çözülmelidir.',
      meaningEn: 'A problem should be addressed while it is still small.',
      contextTr: 'Ufak yazılım hatasını büyümeden düzeltmek için hemen müdahale ettiler.',
      contextEn: 'They fixed the small software defect before it could grow into a larger problem.',
    ),
    ProverbCard(
      id: 'road_companion', minimumStage: 20,
      opening: 'Yoldan kal, yoldaştan', ending: 'kalma.',
      meaningTr: 'Bir işi ertelemek, güvenilir bir yol arkadaşını kaybetmekten iyidir.',
      meaningEn: 'It is better to delay a journey than to lose a trusted companion.',
      contextTr: 'Yardım isteyen arkadaşını yalnız bırakmamak için yolculuğu erteledi.',
      contextEn: 'She postponed the trip rather than leave a friend who needed help alone.',
    ),
    ProverbCard(
      id: 'forced_beauty', minimumStage: 20,
      opening: 'Zorla', ending: 'güzellik olmaz.',
      meaningTr: 'İyi sonuçlar baskıyla değil, gönüllü kabul ve uyumla elde edilir.',
      meaningEn: 'Good outcomes require willing agreement, not coercion.',
      contextTr: 'Ekibi zorlamak yerine öneriyi birlikte değiştirip benimsemelerini sağladı.',
      contextEn: 'Instead of forcing the team, she revised the proposal with them until they accepted it.',
    ),
    ProverbCard(
      id: 'one_disaster_thousand_advice', minimumStage: 20,
      opening: 'Bir musibet', ending: 'bin nasihatten iyidir.',
      meaningTr: 'Yaşanan bir olay, uzun öğütlerden daha etkili ders verebilir.',
      meaningEn: 'A lived experience can teach more effectively than repeated advice.',
      contextTr: 'Bütçesini aşınca, plan yapmanın önemini bu kez gerçekten kavradı.',
      contextEn: 'After overspending, he truly understood why planning a budget matters.',
    ),
    ProverbCard(
      id: 'horse_knows_rider', minimumStage: 20,
      opening: 'At', ending: 'binicisini tanır.',
      meaningTr: 'İnsanlar, karşılarındakinin tutumunu ve becerisini sezer.',
      meaningEn: 'People can sense the attitude and skill of the person dealing with them.',
      contextTr: 'Deneyimli at, acemi binicinin tedirginliğini hemen belli etti.',
      contextEn: 'The experienced horse immediately sensed the novice rider’s unease.',
    ),
    ProverbCard(
      id: 'nightingale_tongue', minimumStage: 20,
      opening: 'Bülbülün çektiği', ending: 'dilinin belasıdır.',
      meaningTr: 'Düşünmeden konuşmak, kişiye kendi sözleri yüzünden sıkıntı çıkarabilir.',
      meaningEn: 'Careless speech can bring trouble upon the speaker.',
      contextTr: 'Sır saklayamadığı için arkadaşının güvenini kaybetti.',
      contextEn: 'He lost his friend’s trust because he could not keep a confidence.',
    ),
    ProverbCard(
      id: 'shepherdless_sheep', minimumStage: 20,
      opening: 'Çobansız koyunu', ending: 'kurt kapar.',
      meaningTr: 'Gözetimsiz ve sahipsiz kalan topluluk zarar görebilir.',
      meaningEn: 'A group left without guidance or protection can be harmed.',
      contextTr: 'Sorumlu kişi olmayınca açık kalan depo kısa sürede dağıldı.',
      contextEn: 'With nobody responsible, the unlocked storeroom quickly fell into disarray.',
    ),
    ProverbCard(
      id: 'fist_millstone', minimumStage: 20,
      opening: 'El yumruğu yemeyen kendi yumruğunu', ending: 'değirmen taşı sanır.',
      meaningTr: 'Gerçek güçle karşılaşmayan kişi kendi gücünü abartabilir.',
      meaningEn: 'Someone untested may overestimate their own strength.',
      contextTr: 'İlk ciddi eleştiriyi alınca hazırlığının ne kadar eksik olduğunu gördü.',
      contextEn: 'After serious feedback, she saw how unprepared she had been.',
    ),
    ProverbCard(
      id: 'two_watermelons', minimumStage: 20,
      opening: 'İki karpuz', ending: 'bir koltuğa sığmaz.',
      meaningTr: 'Bir kişi aynı anda iki büyük işi gerektiği gibi yürütemez.',
      meaningEn: 'One person cannot properly manage two demanding tasks at once.',
      contextTr: 'İki projeyi aynı anda üstlenince ikisinin de takvimi aksadı.',
      contextEn: 'Taking on two projects at once caused both schedules to slip.',
    ),
    ProverbCard(
      id: 'goodwill_sea', minimumStage: 20,
      opening: 'İyilik yap denize at; balık bilmezse', ending: 'Hâlık bilir.',
      meaningTr: 'Karşılık beklemeden yapılan iyilik, değerini yitirmez.',
      meaningEn: 'A good deed remains worthwhile even when no one rewards it.',
      contextTr: 'Adını duyurmak istemeden ihtiyaç sahibine destek oldu.',
      contextEn: 'She helped someone in need without seeking recognition.',
    ),
    ProverbCard(
      id: 'escaped_fish', minimumStage: 20,
      opening: 'Kaçan balık', ending: 'büyük olur.',
      meaningTr: 'Elde edilemeyen fırsat, sonradan olduğundan daha değerli görünür.',
      meaningEn: 'A missed opportunity may seem more valuable in retrospect.',
      contextTr: 'Başvurmadığı işin hayalindeki kadar kusursuz olduğunu düşünmeye başladı.',
      contextEn: 'He began imagining the job he had skipped as more perfect than it was.',
    ),
  ];

  static final List<List<int>> _campaign = _makeCampaign();
  static final List<List<int>> _practice = _makePractice();

  final int stage;
  final List<ProverbCard> cards;
  final List<String> answerOrder;
  final bool isPractice;
  final int round;

  String get boardSignature {
    final List<String> ids = cards.map((ProverbCard card) => card.id).toList()
      ..sort();
    return ids.join('|');
  }

  static ProverbFinishScenario forCampaignLevel(int level) {
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

  static ProverbFinishScenario forPracticeRound(int round) {
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

  static ProverbFinishScenario _build({
    required List<int> indices,
    required int stage,
    required int round,
    required bool isPractice,
  }) {
    final List<ProverbCard> cards = indices
        .map((int index) => _bank[index])
        .toList(growable: false);
    final List<String> endings = cards
        .map((ProverbCard card) => card.ending)
        .toList(growable: true);
    endings.shuffle(
      ContentSeed.randomFor(
        gameId:
            'proverb_finish:${isPractice ? 'practice' : 'campaign'}:answers',
        level: round,
      ),
    );
    return ProverbFinishScenario(
      stage: stage,
      cards: List<ProverbCard>.unmodifiable(cards),
      answerOrder: List<String>.unmodifiable(endings),
      isPractice: isPractice,
      round: round,
    );
  }

  static List<List<int>> _makeCampaign() {
    if (_bank.length != campaignLevels * 4) {
      throw StateError(
        'Campaign needs four distinct proverbs for every level.',
      );
    }
    // Four new entries per level guarantee no proverb is reused in campaign.
    final List<List<int>> result = <List<int>>[];
    for (int level = 1; level <= campaignLevels; level++) {
      final int firstIndex = (level - 1) * 4;
      result.add(
        List<int>.unmodifiable(<int>[
          firstIndex,
          firstIndex + 1,
          firstIndex + 2,
          firstIndex + 3,
        ]),
      );
    }
    return List<List<int>>.unmodifiable(result);
  }

  static List<List<int>> _makePractice() {
    final math.Random random = ContentSeed.randomFor(
      gameId: 'proverb_finish:practice-order',
      level: 1,
    );
    final Set<String> usedSignatures = _campaign.map(_signature).toSet();
    final List<List<int>> result = <List<int>>[];
    final int boardsPerDeck = _bank.length ~/ 4;
    // Each randomized practice deck uses every proverb once before recycling.
    while (result.length < uniquePracticeRounds) {
      List<List<int>>? acceptedDeck;
      for (int attempt = 0; attempt < 1000; attempt++) {
        final List<int> deck = List<int>.generate(
          _bank.length,
          (int index) => index,
        )..shuffle(random);
        final List<List<int>> candidateDeck = <List<int>>[
          for (int board = 0; board < boardsPerDeck; board++)
            deck.sublist(board * 4, board * 4 + 4),
        ];
        final Set<String> deckSignatures = <String>{};
        bool isValid = true;
        for (int index = 0; index < candidateDeck.length; index++) {
          final String signature = _signature(candidateDeck[index]);
          if (usedSignatures.contains(signature) ||
              !deckSignatures.add(signature)) {
            isValid = false;
            break;
          }
        }
        if (isValid && result.isNotEmpty) {
          final Set<int> previousBoard = result.last.toSet();
          if (candidateDeck.first.any(previousBoard.contains)) {
            isValid = false;
          }
        }
        if (isValid) {
          acceptedDeck = candidateDeck;
          break;
        }
      }
      if (acceptedDeck == null) {
        throw StateError('Could not create distinct proverb practice boards.');
      }
      for (final List<int> board in acceptedDeck) {
        if (result.length == uniquePracticeRounds) break;
        usedSignatures.add(_signature(board));
        result.add(List<int>.unmodifiable(board));
      }
    }
    return List<List<int>>.unmodifiable(result);
  }

  static String _signature(List<int> indices) =>
      (indices.map((int index) => _bank[index].id).toList()..sort()).join('|');
}
