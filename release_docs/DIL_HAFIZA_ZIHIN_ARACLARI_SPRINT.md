# Dil, Hafıza ve Zihin Araçları — 20 Maddelik Uygulama Sprinti

## Ürün kararı

Bu sprint, katalogda önceden planlanmış 7 dil/kelime ve 9 hafıza oyununu
oynanabilir ve birbirinden ayrışan deneyimlere dönüştürür. 4 yeni günlük araç,
oyun puanlamasına zorlanmaz; ana ekranda ayrı bir **Zihin Araçları** alanında
sunulur. Mevcut oyun kimlikleri ve ilerleme kayıtları korunur.

Her oyun 20 kampanya seviyesidir; ilk 300 pratik oturumu kampanyadan ve
birbirinden farklı, deterministik ve çözülebilir içerik taşır. 7–10. seviyelerde
zorluk belirgin yükselir; 17–20. seviyeler usta bandıdır. 300 pratik oturumu,
300 seviye anlamına gelmez.

## Sprint sırası

### Dil ve kelime

1. **Anlam Eşleştir** (`meaning_match`, katalog sırası 53): bağlam ve kavram
   ilişkileri; yanlış ama inandırıcı eşleşmeler; her doğru küme için açıklama.
2. **Atasözü Tamamla** (`proverb_finish`, sıra 54): eksik ifade, kullanım
   bağlamı ve yakın kültürel anlamları ayırt etme; kaynaklı açıklamalar.
3. **Cümle Kur** (`sentence_builder`, sıra 56): sözdizimi, noktalama ve ton;
   son seviyelerde iç içe yan cümleler ve çok adımlı düzenleme.
4. **Yakın Anlam** (`near_meaning`, sıra 57): bir kelimenin bağlama en uygun
   tonunu ve anlam nüansını seçme; sözlük ezberinden kaçınma.
5. **Harf Labirenti** (`letter_maze`, sıra 58): düz kelime aramasından farklı
   olarak hece/ek kapıları ve rota kısıtlarıyla sözcük üretme.
6. **Dil Dedektifi** (`language_detective`, sıra 59): kısa metinde niyet,
   çelişki, resmiyet ve anlatım ipuçlarını kanıta dayalı çözme.
7. **Hikâye Sırası** (`story_order`, sıra 60): olayları yalnız zaman değil,
   sebep-sonuç ve anlatı ipuçlarıyla yeniden kurma.

### Hafıza ve dikkat

8. **Işık Dizisi** (`light_sequence`, sıra 33): konum, yön ve değişen kuralları
   hatırlama; ileri seviyelerde yanıltıcı ara uyaranlar.
9. **Kart Çifti** (`card_pairs`, sıra 34): düz eş kart oyunu değil; konum ve
   özellik belleğini farklı eşleştirme kurallarıyla sınama.
10. **Odak Filtresi** (`focus_filter`, sıra 35): hedef seçimi, benzer dikkat
    dağıtıcılar ve yanlış alarm bütçesi.
11. **Değişeni Bul** (`spot_change`, sıra 36): sahne ve nesneler arasındaki
    konum/ilişki değişimlerini kontrollü gözlemle bulma.
12. **Ritim Hafızası** (`rhythm_memory`, sıra 37): ses ve sessizlik vuruşlarını
    hatırlama; sessiz oynama ve ses seviyesi erişilebilirliği.
13. **Sembol Akışı** (`symbol_stream`, sıra 38): akış bilgisini güncelleme,
    gecikmeli hatırlama ve değişen kuralı izleme.
14. **Sessiz Sayım** (`silent_count`, sıra 39): örtülen olayları tür ve adet
    olarak izleme; görsel erişilebilirlik desteği.
15. **Dikkat Tüneli** (`attention_tunnel`, sıra 40): hareketli sahnede hedefi
    izleyip nadir işareti yakalama; flaşsız animasyon seçeneği.
16. **İkili Görev** (`dual_task`, sıra 41): ana görevi sürdürürken ikinci kısa
    bilgiyi akılda tutma; iki beceriyi ayrı ölçme ve adil yük ayarı.

### Zihin Araçları (oyun dışı, yerel öncelikli)

17. **Akıllı Kelime Defteri** (`vocabulary_notebook`): kullanıcının kendi
    kelime/not/örneklerini kaydettiği ve zorluk derecesine göre geri çağırdığı
    aralıklı tekrar aracı.
18. **Alışveriş ve Hazırlık Asistanı** (`smart_list`): gerçek alışveriş,
    seyahat ve yapılacak listeleri; isteğe bağlı kısa süreli hatırlama pratiği.
    Kullanıcı listeleri cihazda tutulur.
19. **Oku–Dinle–Hatırla** (`read_listen_recall`): editörlü özgün mikro içerik,
    cihazdaki en iyi uyumlu çevrimdışı ses, anlama soruları, kelime kaydı ve
    planlı gecikmeli hatırlama.
20. **Günlük Konuşma Görevleri** (`daily_dialogues`): alışveriş, yol tarifi,
    randevu ve iş iletişimi gibi senaryolarda çevrimdışı, editörlü dallanan
    diyaloglar. Ses kaydı isteğe bağlıdır.

## Ortak kalite kapısı

- Her oyun kimliği, katalog kartı, ayrı ilerleme anahtarı, hub, ana sayfa,
  öneri/ilerleme kayıtları ve uygun mevcut günlük/yarışma köprülerine bağlanır.
- Her kampanya 20 seviye; 7–10 ileri, 17–20 usta; çözülebilirlik ve seviyeler
  arası gerçek zorluk artışı senaryo testinde doğrulanır.
- İlk 300 pratik içerik imza düzeyinde benzersizdir; aynı kelime listesine
  yalnız farklı sıra vermek tek başına yeni senaryo sayılmaz.
- Türkçe içerikte yazım, ek, anlam ve cevap anahtarı doğrulanır. Çoktan seçmeli
  soruda bağlam içinde yalnız bir savunulabilir doğru cevap bulunur.
- 320×600 telefon ve 800×1280 tablet; Türkçe/İngilizce; büyük yazı, yatay
  kaydırma, düğme erişimi, pause/lifecycle, ipucu, yanlış cevap ve bitiş akışı
  test edilir.
- Oyunlar mevcut sakin açık menü, oyun sınıfı paleti, ortak ses profili ve
  bölüm tebrik akışını kullanır. Zihin Araçları sessiz ve sakin; ödül/puan
  yalnızca kullanıcı isteğiyle açılan pratik moduna aittir.
- Yeni bir madde, kendi motor testi, ekran testi, içerik benzersizliği testi,
  ana oyun merkezi smoke testi ve `flutter analyze` geçmeden tamamlandı sayılmaz.

## Durum

**20/20 tamamlandı.**

- **Anlam Eşleştir:** 20 kampanya seviyesi (7–10 ileri, 17–20 usta),
  kampanyadan ayrı ilk 300 benzersiz pratik tahtası; Türkçe/İngilizce oynanış ve
  seviye haritası; katalog/ana ekran/öneri, günlük parkur, görev, düello ve arena
  bağlantıları doğrulandı.
- **Atasözü Tamamla:** 20 kademeli bölüm, 300 kampanyadan ayrı ve birbirinden
  farklı dört-sözlük pratik tahtası; açıklamalı kullanım bağlamı, ipucu, hata
  bütçesi ve ortak ses/tebrik akışı eklendi. Katalog/ana ekran/öneri, günlük
  parkur/görev, düello ve grup arenası ile ilgili Firestore izin listeleri
  bağlandı.
- **Cümle Kur:** bağlam, bağlaç ve noktalama ipuçlarıyla anlamlı cümle
  bloklarını yeniden kurma; geri al/temizle, ipucu ve cümle mantığı açıklaması
  eklendi. 20 seviyelik kampanya ve ilk 300 kampanya dışı benzersiz dört-cümle
  tahtası; ana katalog/ana ekran/öneri, günlük rota/görev, düello ve arena
  bağlantıları tamamlandı.
- **Yakın Anlam:** sözcük nüansı bağlam içinde çözdürülüyor; doğru yanıtın
  gerekçesi ve yakın sözcükler gösteriliyor. 20 seviyelik kademeli kampanya,
  ilk 300 kampanya dışı benzersiz pratik tahtası, TR/EN ekran akışı ve katalog/
  ana ekran/günlük rota-görev/düello/arena bağlantıları tamamlandı.
- **Harf Labirenti:** ipucundan sözcüğü çıkarıp 5×5 harf rotasını giriş, kök
  kapısı ve çıkıştan geçirme; iki denemeli ipucu/rota düzenleme ve açıklamalı
  bitiş eklendi. TR/EN 20 seviye (7–10 ileri, 17–20 uzman), ilk 300 kampanya
  dışı benzersiz rota, ayrı ilerleme anahtarı ve günlük/düello/arena bağlantıları
  doğrulandı.
- **Dil Dedektifi:** kısa kaynak dosyalarında niyet, olgu/yorum, çelişki,
  örneklem, nedensellik, yönlendirme ve taban oranı vakaları; her doğru yanıt
  için metin kanıtı ve gerekçe eklendi. TR/EN 20 bölüm, 4 vakalık tahtalar, ilk
  300 farklı pratik dosyası, 7–10 ileri/17–20 uzman kademe ve ana/günlük/
  düello/arena bağlantıları tamamlandı.
- **Hikâye Sırası:** olayları neden-sonuç ve kayıt ipuçlarına göre sıralama;
  ileri seviyelerde ilgisiz notu ayıklama ve gerekçeli sonuç eklendi. TR/EN 20
  kampanya dosyası, ilk 300 kampanyadan ayrı benzersiz pratik dosyası, 7–10
  ileri/17–20 usta kademe ve ana menü/öneri/günlük parkur/görev/düello/arena
  bağlantıları doğrulandı.
- **Işık Dizisi:** dokunarak tekrar edilen uzamsal ışık örüntüsü; 7. seviyeden
  itibaren kırmızı sahte flaşlar, 11’den itibaren ters hatırlama, son seviyelerde
  11 sinyal/4 yanıltıcı/tek hata hakkı eklendi. 20 kampanya, 300 benzersiz ve
  kampanyadan ayrı pratik örüntüsü; sessiz haptik destekli ortak ses profili ve
  ana ekran/günlük/düello/arena bağlantıları doğrulandı.
- **Kart Çifti:** aynı görsel, şekil, renk ve anlam ilişkileri arasında değişen
  20 seviyelik eşleştirme sistemi; 7. seviyeden itibaren yanıltıcı kartlar ve
  son bölümlerde daha geniş, hata bütçeli tahtalar. Kampanyadan ayrı ilk 300
  pratik tahta benzersiz; küçük telefon ve tablet ekranında oynanış, TR/EN
  seviye merkezi, ana ekran/katalog/öneri, günlük rota/görev, düello ve arena
  bağlantıları doğrulandı.
- **Odak Filtresi:** go/no-go görsel dikkat akışı; tek özellikten iki koşullu
  filtreye, yarıda değişen kurala, nadir sinyale ve önceki şekli hatırlama
  finaline ilerliyor. Yanlış hedef seçimi ve kaçırılan sinyal ayrı hata bütçesine
  yazılıyor. 20 kampanya seviyesi, ilk 300 kampanyadan ayrı ve birbiriyle
  benzersiz pratik akışı; 320×600’de ana kontroller kaydırmasız, 800×1280
  bölüm merkezi, TR/EN, günlük rota/görev, öneri, düello ve arena bağlantıları
  doğrulandı.
- **Değişeni Bul:** soyut nesnelerin şekil, renk, yön, desen, boyut ve işaret
  değişimlerini önce/sonra karşılaştırmasıyla bulma; ileri seviyelerde nesneler
  arası yer değiştirmeyi ayırt etme. 20 kampanya sahnesi ve ilk 300 benzersiz,
  kampanyadan ayrı pratik sahnesi; 7–10 ileri, 17–20 uzman yoğunluğu; 320×600
  Türkçe oynanış ve 800×1280 İngilizce bölüm merkezi; ana menü, günlük rota,
  görev, düello, arena ve Firestore listeleri doğrulandı.
- **Ritim Hafızası:** sekiz mevcut nota örneğini kullanan işitsel örüntü;
  kısa/uzun/uzatılmış sessizlik, dokunma-basılı tutma vurgusu ve 11. seviyeden
  sonra ters çağırma. 20 kampanya düzeyi ile kampanyaya karışmayan ilk 300
  farklı örüntü çakışma denetimiyle oluşturuluyor. Sessiz modda aynı nota pad'i
  animasyonu ve titreşim çalışıyor; uygulama arka plana alınırsa oynatma güvenle
  kesilip baştan dinlenebiliyor. 320×600 telefon ve 800×1280 İngilizce merkez;
  günlük parkur/görev, arena, düello, profil ve ilerleme bağlantıları doğrulandı.
- **Sembol Akışı:** N-back çalışma belleği akışı; 1-geriden başlayıp ileri
  seviyelerde 2/3-geriye geçiş yapıyor, karşılaştırma kuralı akış içinde değişiyor.
  Son seviye 16 sembol ve iki kural kayması içeriyor. İlk 300 pratik akışının
  hem kampanyadan hem birbirinden imza düzeyinde farklı olduğu, her cevap
  anahtarının doğru gerideki hedefe baktığı test edildi. 320×600 ve 800×1280
  ekranlar, Türkçe/İngilizce, günlük parkur, görev, öneri, katalog, düello,
  arena, profil ve Firestore kayıt izinleri bağlandı.
- **Sessiz Sayım:** başlangıç envanterinden sonra tek tek gösterilip geçmişi
  kapatılan giriş/çıkış oklarını zihinde güncelleme; bazı seviyelerde ters kapı
  kuralı akış ortasında bir ila üç kez değişiyor. Sayımın sonunda iki türden
  beş türe kadar her bölme ayrı denetleniyor. 20 seviye ve kampanyadan ayrı ilk
  300 benzersiz akış; kural uygulaması, 0–9 aralığındaki sonuçlar, telefon ve
  tablet yerleşimi doğrulandı. Ana menü/ilerleme, öneriler, katalog, günlük
  görev/parkur, arena, düello, profil ve Firestore listelerine bağlandı.
- **Dikkat Tüneli:** başlangıçta belirginleştirilen aynı nesneyi kesişen
  hatlarda hareket ederken takip etme; geç bölümlerde eşzamanlı çapraz geçiş ve
  kısa kapak örtülmesi var. Hat sayısı üçten dokuza, hareket 5'ten 22'ye çıkar;
  son bölüm dört örtülme ve tek hata hakkıyla kapanır. Her adımın hedef-konum
  cevabı gerçek nesne permütasyonundan türetiliyor. İlk 300 pratik rotası
  benzersiz ve kampanyadan ayrık. Ana ekran, ilerleme, öneriler, katalog, günlük
  rota/görev, arena, düello, profil ve Firestore havuzlarına bağlandı.
- **İkili Görev:** hızlı görsel eşleştirme/ayırt etme akışı sürerken ara sıra
  çıkan sayı kartlarını bellekte tutma; görsel dikkat ve sayı geri çağırma ayrı
  puanlanıyor. Kurallar şekilden şekil+renge kayıyor; 7–10 hız/yanıltıcı,
  17–20 yoğun kural geçişi ve 6 sayıyı tersten hatırlama içeriyor. 20 kampanya
  seviyesi ve birbirinden/kampanyadan ayrı ilk 300 pratik çifti; güvenli
  zaman aşımı, uygulama arka plan yaşam döngüsü, hızlı giriş sınırları, telefon
  ve tablet ekranı, katalog, ana ekran, günlük parkur/görev, düello, arena,
  ilerleme ve Firestore sözleşmeleri doğrulandı.
- **Akıllı Kelime Defteri:** kelime, anlam ve örnek cümleyi cihazda saklama;
  arama, düzenleme ve silme; kullanıcı bildirimini geri çağırma ardından açma;
  “Tekrar / Zor / İyi / Kolay” yanıtlarıyla 10 dakika–günler ölçeğinde yerel
  aralık planlama eklendi. Yinelenen kelimeler engelleniyor, düzenlemede
  geçmiş korunuyor; uygulama puanları ve sıralamalardan ayrı tutuluyor. 320×600
  Türkçe ekle–hatırla–planla akışı ve 800×1280 araç kartı doğrulandı.
- **Alışveriş ve Hazırlık Asistanı:** alışveriş, seyahat ve yapılacaklar türü
  yerel listeler; adet/miktar ve bölüm notları, tamamla/geri al, tamamlananları
  temizleme, yinelenen kayıt engeli, yeniden adlandırma ve onaylı silme eklendi.
  Ayrı ve isteğe bağlı hatırlama modunda kullanıcı listeyi kendi hızında inceler,
  gizler, hatırladığı maddeleri satır satır yazar ve yerel geri bildirim alır.
  Tekrar yanıtları sonucu şişirmez; yanıt, puan, ilerleme ve sıralama kalıcı
  kayda girmez. 320×600’de liste kurma/tamamlama ve uçtan uca hatırlama, 800×1280
  araç kartı, yerel kalıcılık ve liste yaşam döngüsü testleri doğrulandı.
- **Oku–Dinle–Hatırla:** beş özgün Türkçe/İngilizce mikro öykü; her metinde
  metin kanıtına dayalı sorular, gerekçeli yanıt ve bir sözcüğü Kelime
  Defteri'ne aktarma eklendi. Android, dile/bölgeye uygun en iyi kalite internet
  gerektirmeyen kurulu sesi seçer; uyumlu ses yoksa okuma ve soru çalışması
  sürer. İlk tamamlamadan bir gün sonra, metni açmadan soru soran yerel tekrar
  turu gelir; doğru hatırlamada aralık 3 günden başlayarak en çok 30 güne kadar
  ikiye katlanır, zorlanmada 1 güne döner. Eski tamamlanmış metinler yerel
  tekrar kuyruğuna alınır. 320×600 okuma ve gecikmeli tekrar; 800×1280 merkez;
  Android debug derlemesi doğrulandı.
- **Günlük Konuşma Görevleri:** kafe siparişi, yol tarifi, randevu ve iş teslimi
  için dört özgün Türkçe/İngilizce dallanan konuşma ağacı eklendi. Seçimler
  karşı tarafın yanıtını/sonraki adımı değiştirir; her dalda netlik gerekçesi,
  daha iyi ifade ve yerel en iyi netlik kaydı bulunur. Mikrofon, ses kaydı,
  oyun puanı ve çevrimiçi sıralama yoktur. Senaryo grafiği bütünlüğü, cihazda
  ilerleme, 320×600 iki karar akışı ve 800×1280 merkez doğrulandı.

Tüm proje regresyonunda 745 test geçti. Kalan tek başarısızlık, 27 oyunluk güncel
katalogda 11 oyun bekleyen eski statik sayım testiydi; kontrolü katalog uzunluğuna
bağlandı ve ilgili sözleşme dosyası 6/6 geçti. Böylece son kaynak durumunda
746/746 test için geçiş kanıtı var. Etkilenen Dart kodlarının analizi temiz;
Android debug APK'sı `build/app/outputs/flutter-apk/app-debug.apk` konumuna
başarıyla derlendi.
