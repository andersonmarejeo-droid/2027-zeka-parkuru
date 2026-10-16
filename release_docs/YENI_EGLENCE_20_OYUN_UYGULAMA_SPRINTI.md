# Zekâ Parkuru — Yeni Eğlence 20 Oyun/Uygulama Sprinti

> **Bu dosya bir üretim planıdır; mevcut oyun kodunu, katalog kayıtlarını, seviyeleri veya sesleri değiştirmez.** Kapsam, projede var olan oyunlara dokunmadan 20 yeni ve birbirinden farklı eğlence deneyimini tasarlamak, sonra her birini bağımsız sprintte geliştirmek ve doğrulamaktır.

## 1. Amaç ve ürün kararı

Bu seri, yalnızca “20 yeni kart” üretmek yerine uygulamaya farklı oyuncu motivasyonları getirir: kısa rekabet, ustalaşma, rahatlatıcı üretim, yönetim, macera ve arkadaşlarla oynama. Her oyun tek cümlede açıklanabilen bir ana vaat ve oyunlar arasında değişen bir ana kontrol/karar döngüsü taşır. Benzer görünümlü oyunlar farklı isimle tekrar edilmez.

Sensor Tower'ın 2026 rapor özeti, 2025'te mobil oyun gelirinin 82 milyar dolara çıktığını; indirmeler yavaşlarken elde tutma ve etkileşimin önem kazandığını, mobilde stratejinin gelir/indirme/oyun süresinde aynı anda büyüyen tek tür olduğunu belirtiyor. 2025 rapor özeti ise Batı pazarında Casual oyunların yüksek harcama payını ve oyuncu etkileşiminin önemini vurguluyor. Bunlar başarı garantisi değil; bu sprintte kısa oturumları, tekrar oynama sebebini ve tür çeşitliliğini birlikte tasarlama gerekçesidir. [Sensor Tower — State of Gaming 2026](https://sensortower.com/press/press-release-sensor-tower-state-of-gaming-gaming-drove-52-billion-downloads-82b-iap-revenue-on-mobile-and-12b-premium-revenue-on-steam) · [Sensor Tower — State of Mobile Gaming 2025](https://sensortower.com/press/press-release-sensor-tower-mobile-gaming-rebounds-in-2024-as-player-engagement-and-spending-reach-new-highs)

## 2. Mevcut projeyi koruma ve çakışma denetimi

Plan hazırlanırken `StudioGameCatalog`, `lib/games` ve önceki `EĞLENCE_20_SERISI_SPRINT.md` incelendi. Önceki Eğlence 20 serisi katalogdaki mevcut 12 kimliği ve 8 yeni kimliği kullanarak tamamlanmış; Balon Avcısı, Şişe Kırmaca, Renk Reaktörü, Top Birleştir, Kule Denge, Mıknatıs Rotası, Mini Golf Rota, Şeker Konveyörü, Halka At, Küçük Balıkçı, Mermer Rota, Blok Akışı, Kâğıt Uçak, Neon Pinball, Uçurtma Pilotu, Ritim Atölyesi, Kaykay, Kar Sörfü, Jetpack Kurye ve Yörünge Kurtarma bu kapsamın dışındadır.

Yeni öneriler bunların yeniden adlandırılmış sürümleri değildir. Ayrıca mevcut mantık, hafıza, kelime, sayı, masa oyunu ve refleks oyunlarının kuralları kopyalanmaz. **S01–S20, 80.–99. girişler olarak ayrı kimliklerle eğlence kataloğuna eklendi.** Önceki oyunların kayıt anahtarları değiştirilmedi. Mevcut `StudioGameClass.fun`, `StudioGameSession`, `GameAudioService`, ortak sonuç/tebrik, ilerleme kayıtları ve oyun merkezi ortak altyapı olarak kullanılır.

## 3. Ana sınıflandırma ve içerik dengesi

Ana uygulama sınıfı **Eğlence** olarak kalır. Bu seri, ana sayfada 20 yeni sınıf açmak yerine Eğlence içinde beş keşif koleksiyonu kullanır. Böylece kullanıcı yeni oyunları bulur ama katalog gereksiz yere bölünmez.

| Koleksiyon | Adet | Oyuncuya verdiği deneyim | Ortak görsel vurgusu |
|---|---:|---|---|
| Spor ve rekabet | 4 | Kısa tur, fizik, rakip ve ustalık | Açık saha beyazı, koyu petrol çizgiler, mercan hedef |
| Aksiyon ve keşif | 4 | Gerilim, rota kararı, risk ve bölüm sonu | Fildişi HUD, derin lacivert sahne, tek sıcak vurgu |
| Rahat üretim ve bakım | 4 | Yaratıcılık, müşteri/canlı bakımı ve koleksiyon | Kırık beyaz, adaçayı/deniz camı, yumuşak gölge |
| Dünya kurma ve yönetim | 4 | Kaynak, yerleşim, trafik ve planlama | Açık taş/krem zemin, ölçülü teal ve amber |
| Arkadaşlarla masa/parti | 4 | Bluff, işbirliği, gizli bilgi ve taktik | Açık oyun masası, okunaklı taş/kart yüzleri, kontrastlı vurgu |

Görsel aileler aynı uygulamanın parçası olduğunu ortak tipografi, kart geometrisi, boşluk, kenar yarıçapı, durum renkleri, HUD ve sonuç ekranıyla belli eder. Her oyun kendi sahne materyaline ve karakterine sahip olur. Açık katalog yüzeyi oyun alanının kontrastını düşürmez. Hedef “Unity'de üretilmiş” izlenimi veren derli toplu malzeme/ışık/hareket kalitesidir; mevcut Flutter mimarisinde bu hedef özel Canvas/vektör çizimi ve katmanlı 2.5D sahneyle yakalanır, motor değişikliği veya sahte 3D vaadi değildir.

## 4. Değişmez oyun kalite standardı

1. **20 kampanya seviyesi:** 1–3 ana kontrolü güvenle öğretir; 4–6 ikinci karar katmanını ekler; 7–10 belirgin biçimde zorlaşır (özellikle 9–10 ustalık eşiği); 11–16 birleşik sistemleri öğretir; 17–20 uzman final/boss sözleşmesine ulaşır. Zorluk yalnız hız, nesne ya da süreyi artırarak kurulmaz.
2. **Tekrarsızlık:** Sabit kampanya seviyesi kendi ekranını korur. İlk 300 tekrar/serbest oynanış senaryosu kampanya ve birbirinden imza düzeyinde farklı olur. Simülasyon oyunlarında “senaryo imzası”, spor oyunlarında parkur/rakip/koşul kombinasyonu, parti oyunlarında vaka/kart/rol dağılımı ölçülür. Seed tekrar üretilebilir olmalı; imza eşleşmesi varsa üretici başka senaryo vermelidir.
3. **Adil oynanış:** Rastgelelik oyuncuya karşı haksız sonuç üretmez. Seviye ve görevler mümkün/çözülebilirlik, hedefe erişim, kaynak bütçesi, rakip adaleti ve başarısızlığın açıklanabilirliği bakımından otomatik ya da simülasyon testinden geçer.
4. **Dokunma ve ekran:** 320×600 Türkçe telefon, 800×1280 İngilizce tablet, güvenli alanlar, 48 dp hedef, harf ve sayı sığması, yatay/dikey taşma, kaydırma sınırı, başparmak erişimi ve küçük ekranda sabit oyun alanı test edilir. Etkileşim yalnız renk ya da sesle anlatılmaz.
5. **Profesyonel çizim:** Rastgele AI görselleri, emoji varlıklar, düzensiz ikonlar, aşırı neon/glow, gürültülü arka plan veya sahte ışık efekti kullanılmaz. Her oyun için önce sanat yönü, sahne bloklaması, materyal/ışık örneği ve HUD yerleşimi onaylanmış tasarım artefaktı oluşturulur; sonra oynanış kodlanır. Ana varlıklar projeye özgü vektör/Canvas ya da lisansı doğrulanmış optimize asset olur.
6. **Hareket ve performans:** Kamera amacı belirsiz biçimde kaymaz; hareket, hız, çarpışma ve yerleştirme oyuncu girdisiyle tutarlı kalır. 60 fps hedefi, düşük cihaz davranışı, uygulama arka plana geçişi, pause/resume, reduced-motion ve titreşimi kapatma sınanır.
7. **Ses ve kutlama:** Mevcut `GameAudioService` organizasyonu ve sınıf profili kullanılır. Her oyun için kısa, temiz ve telif/lisansı doğrulanmış olay sesleri tanımlanır; ses spam'i, clipping ve üst üste binme sınırlandırılır. Sessiz kullanım tam oynanır; mevcut bölüm sonu tebrik/sonuç akışı korunur.
8. **Geliştirme kabulü:** Oyun ancak kural/etkileşim testleri, kampanya zorluk testi, 300 senaryo tekillik sertifikası, telefon/tablet UI testi, TR/EN metin kontrolü, ses/sonuç sözleşmesi, katalog/oyun merkezi açılışı, statik analiz ve proje regresyonu geçince tamamlanır. Mevcut oyunların testleri ve kayıtları geriye dönük bozulmaz.

## 5. Ortak hazırlık sprinti — oyunlardan önce (S00)

| Adım | Teslim |
|---:|---|
| 01 | Katalogdaki kimlikleri, oynanabilir durumları, mevcut fun oyunlarını ve tüm oyun kayıt anahtarlarını dondurulmuş referans olarak çıkar. |
| 02 | 20 adayın kimlik, kontrol şeması, temel döngü ve görsel silüet çakışmasını tek tek denetle; çakışan adayı kod başlamadan değiştir. |
| 03 | Eğlence koleksiyonları için kategori etiketlerini, filtre/arama ve keşif kartı bilgisini tanımla; eski kartların sırasını bozma. |
| 04 | Ortak açık görsel sistemin tipografi, boşluk, yüzey, kart, gölge, buton, durum ve erişilebilirlik tokenlarını belirle. |
| 05 | Telefon/tablet güvenli oyun çerçevesi, sabit HUD, alt kontrol alanı ve ortak pause/help/result katmanını ölçülendir. |
| 06 | Yeni oyun başına ayrı ilerleme namespace'i, deterministik seed ve içerik imzası sözleşmesini tasarla; var olan save key'lere dokunma. |
| 07 | Oyun sınıfı ses profilinin olay adları, ses limiti, haptik yoğunluğu ve tebrik geçişini doğrula. |
| 08 | Ortak test cihazı ölçüleri, İngilizce uzun metin örnekleri, renk körlüğü/reduced-motion ayarları ve görsel altın görüntü testlerini kur. |
| 09 | İlk iki prototipte (drift ve kafe) performans/mimari riskini ölç; başarısız prototip varsa 20 oyuna yaymadan tekniği düzelt. |
| 10 | S01'e geçiş için “mevcut katalog ve mevcut oyun regresyonu temiz” temel raporunu kaydet. |

## 6. Yirmi bağımsız oyun sprinti

### Koleksiyon A — Spor ve rekabet

#### S01 — Drift Ligi (`drift_league`)

- **Vaadi ve döngüsü:** Kısa pistlerde arabayı virajın girişinde frenle, kontrollü kaydır, çıkışta tutuşu geri kazan; temiz drift zinciriyle süre ve stil puanını birlikte geliştir. Tek parmak yön, ayrı gaz/fren ya da erişilebilir otomatik gaz seçeneği.
- **Derinlik/zorluk:** Pist şekilleri, yüzey tutuşu, lastik sıcaklığı, drift açısı ve hedef kapıları farklı kombinasyonlanır. 7–10 dar kapı/az hata ve değişen tutuş ister; 17–20 ardışık drift zinciri + temiz bitiş ister. Hız tek başına zorluk ölçütü değildir.
- **Sanat/ses:** Üstten okunaklı minyatür pist, gölgeli araç gövdesi, mat asfalt, boyalı apex ve kısa lastik izi; kamera arabayı kesmez. Motor sesi hızla ama miks limitiyle değişir; lastik kayması ve temiz drift için ayrı yumuşak Foley.
- **Kabul kanıtı:** Tüm kapıların erişilebilirliği simüle edilir; dokunma/tilt opsiyonları tutarlı; duraklatma sonrası fizik sıfırlanmaz; 300 pist-yüzey-rakip koşulu farklı imzalıdır.

#### S02 — Masa Tenisi Rallisi (`table_tennis_rally`)

- **Vaadi ve döngüsü:** Rakibin vuruş hazırlığını okuyup raketi konumlandır; zamanlama penceresinde vuruşu seç, topspin/slice etkisi ver ve ralliyi puana çevir. Oyun yalnız hedefe hızlı dokunma değildir: pozisyon, vuruş açısı ve spin seçimi karar üretir.
- **Derinlik/zorluk:** 20 maçlık tur, oyuncu için servis öğretimi, rallide yön, spin, kısa top ve köşe hedeflerini katmanlar. 7–10 rakip spinini karşılamayı; 17–20 karışık servis + yer değiştirme + son vuruş kararını ister. Rakip yapay biçimde topa ışınlanmaz; tepki, erişim ve hata olasılığı seviyeye göre görünür.
- **Sanat/ses:** Temiz açık ahşap masa, kauçuk raket yüzeyi, top gölgesi ve az parçacıklı temas izi. Top sekmesi örnekleri ölçülü katmanlanır; müzik/ambiyans rallinin sesini örtmez.
- **Kabul kanıtı:** Sabit adım top simülasyonu, köşe/kenar ve sekme testleri, oyuncu kazanabilir rakip profili, küçük ekranda raket kontrol alanı ve 300 servis/ralli konumu tekillik kontrolü.

#### S03 — Penaltı Zihin Oyunu (`penalty_mindgame`)

- **Vaadi ve döngüsü:** Oyuncu şutör ve kaleci rollerini sırayla üstlenir; yaklaşma animasyonu ve kalça/omuz ipuçlarından yön çıkarır, atışta güç ve köşeyi; kalede ise dalış zamanını seçer. İki yönlü rol, salt refleks tıklamasından ayrılır.
- **Derinlik/zorluk:** 20 seri, önce tek ipucu sonra sahte vücut hareketi, değişen şut hızı, ıslak zemin ve kalecinin küçük hareket alanı ekler. 7–10 birden çok ipucunu çapraz okumayı, 17–20 beş atışlık baskı serisinde rakip alışkanlığını izlemeyi ister. Oyuncu adaletsiz gizli RNG ile kaybettirilmez.
- **Sanat/ses:** Açık stadyum çimi, katmanlı saha çizgisi, doğru oranlı top/kaleci ve sade, yayın grafiği gibi skor paneli. Şut teması, ağ ve kaleci eldiveni kısa ve gerçekçi; kutlama ortak sonuç sistemine bağlanır.
- **Kabul kanıtı:** Her atış penceresi görsel/işitsel/sessiz alternatif ipucuna sahiptir; iki rol de oynanabilir; top kale/kaleci/kale direği sınır testleri ve her seed'de skor imkânı belgelenir.

#### S04 — Air Hockey: Arena (`air_hockey_arena`)

- **Vaadi ve döngüsü:** Kendi tokmağını masanın yarısında konumlandır; savunmadan hücum açısına geç, duvar sekmelerini okuyup diski kaleye yönlendir. Gerçek zamanlı rakip, açık maç ve hedef senaryoları.
- **Derinlik/zorluk:** Hız, sürtünme, disk çarpışması ve rakip karar profili ayarlanır. 7–10 çift sekme ve kaleyi savunma/hücum dengesi; 17–20 kısa baskı penceresinde hücumdan savunmaya dönüş ister. Sadece disk hızını artırarak zorluk yapılmaz.
- **Sanat/ses:** Yüksek kontrastlı ancak açık yüzeyli buz-cam masa, kalın saha sınırları, disk gölgesi, oyuncu tokmağı ve hedef alanı. Disk çarpışma sesi hızı/şiddetiyle normalize edilir; gol efekti kısa kalır.
- **Kabul kanıtı:** Ayrık zaman fizik, kenar sekmesi ve aynı konumlu temas testleri; AI tepkisi gecikmeli ve tahmin edilebilir; dokunma alanı ve disk görseli üst üste gelince yanlış dokunuş önleme.

### Koleksiyon B — Aksiyon ve keşif

#### S05 — Kalıntı Seferi (`relic_run`)

- **Vaadi ve döngüsü:** Kısa odalarda karakteri sürükle değil sanal yön pediyle hareket ettir; kaçınma hamlesi, hedefli araç ve kalıntı yeteneğini doğru sırada kullanıp çıkışa ulaş. Her koşuda üç oda ve güvenli seçim durağı.
- **Derinlik/zorluk:** Farklı düşman telegraph'ları, engel katmanları, sınırlı iyileşme ve birbiriyle etkileşen kalıntı pasifleri kullanılır. 7–10 iki tehdit tipini aynı odada çözdürür; 17–20 boss saldırı döngüsü ve seçilen ekipmanı birlikte sınar. Pay-to-win/gacha yok; tüm yetenekler oynanışla açılır.
- **Sanat/ses:** El çizimi gibi temiz vektör taş odalar, düşük gürültülü katmanlı duvarlar, karakter silüeti ve düşman saldırısında okunaklı ön işaret. Müzik/ambiyans ayrı bus; saldırı, kaçınma, hasar ve ödül sesleri kısa ve ayırt edilir.
- **Kabul kanıtı:** Çarpışma kutusu, saldırı telegraph'ı, hasar/yenilmezlik penceresi, oda geçişi ve boss saldırı testleri; her kampanya rotası bitirilebilir; seed/oda/loot birleşimleri 300 tekrar boyunca imza düzeyinde farklı.

#### S06 — Fener Savunması (`lighthouse_defense`)

- **Vaadi ve döngüsü:** Fener çevresindeki patikalara sınırlı savunma yapıları yerleştir; dalga başlamadan hedef önceliği/menzil/iyileştirme seç; dalga sırasında bir seferlik güç kullan. Kule savunması türü ilk defa eklenir, mevcut çizgi-rotası bulmacası gibi çalışmaz.
- **Derinlik/zorluk:** Düşman zırhı, hava durumu, yol ayrımı, kule sinerjisi ve enerji bütçesi kademeli gelir. 7–10 kule kombinasyonunu ve hedef önceliğini; 17–20 farklı dalga rollerine göre önceden planlamayı gerektirir. Her görev, mümkün savunma çözümüyle sertifikalanır.
- **Sanat/ses:** Fildişi/parşömen taktik haritası üstünde sahne derinliği taşıyan fener, taş kule ve düşman; mermi efektleri küçük ve okunaklıdır. Top atışı/titreşimli ışık ve dalga bitişi ayrı ses katmanlarıdır.
- **Kabul kanıtı:** Düşman yol bulma, menzil/hedef seçimi, dalga simülasyonu, FPS hedefi, kule yerleşim hitbox'ı ve kampanya kaybetme/yeniden deneme dengesi test edilir; seed'ler çözüm imkânını korur.

#### S07 — Müze: Gece Vardiyası (`museum_after_hours`)

- **Vaadi ve döngüsü:** Kare tabanlı galeri haritasında görüş konilerini, devriye adımını ve lazer çevrimini oku; gölge hücresinde güvenle bekle, tek dikkat dağıtıcıyı zamanla, eserleri al ve çıkışa ilerle. Dövüş/koruma temizleme yoktur; oyuncu tehdit hattından kaçar.
- **Derinlik/zorluk:** 1–3 gölge rotası, 4–6 lazer çevrimi, 7–10 iki devriye ve daha sıkı zamanlama, 11–16 uzayan görüş/ikinci lazer, 17–20 üç eser/üç devriye/üçüncü lazer katmanı eklenir. Her haritada tüm yürünebilir alt koridorlar açık; güvenli çıkış rotası otomatik simülasyonla sınanır.
- **Sanat/ses:** Açık krem taş zemin, fildişi kaideler ve bronz eser vurgusu; petrol tonlu gölge hücreleri, duvar gölgesi, yönü gösteren devriye silüeti ve mercan lazer uyarısı özel Canvas sahnesinde çizilir. Oyun ortak Fun ses profilini, sessiz modda görünür durum ipuçlarını ve ortak sonuç/tebrik akışını kullanır.
- **Kabul kanıtı:** Görüş konisi/duvar görüş çizgisi, devriye adımı, saklanarak tur ilerletme, lazer alarmı, eser/çıkış önkoşulu, 20 seviyenin güvenli rota simülasyonu ve 300 pratik harita imzası; 320×600 TR ve 800×1280 EN ekranlarında sabit HUD/kontrol düzeni.

#### S08 — Derin Akıntı (`deep_current`)

- **Vaadi ve döngüsü:** Mini denizaltıda itki ve balastı ayarla; sonar ping'iyle enkazı tara, basınç/oksijen/kablo uzunluğunu yönet, parçayı topla ve güvenli üsse dön. Yörünge kurtarmanın uzay fiziği değil, sualtı keşif ve görev kaynakları ana döngüdür.
- **Derinlik/zorluk:** Akıntı yönü, görüş, batarya, kırılgan yük, derinlik eşiği ve geri dönüş yakıtı katmanlanır. 7–10 toplama hedefi ve emniyetli dönüş birlikte; 17–20 iki durak/tek şarj kaynağı ve hasarsız yük gerektirir.
- **Sanat/ses:** Katmanlı açık/derin mavi su, cihaz ışığı, metal gövde yansıması, parçacıklar düşük yoğunlukta ve derinlik kademeli. Sonar, motor ve gövde vuruşu filtreli ama asla hedef bilgisinin tek kaynağı değildir.
- **Kabul kanıtı:** Basınç/oksijen/enerji değer sınırları, sonar görünürlüğü, gövde çarpışması, görev imkânı ve geri dönüş bütçesi her seed'de simülasyonla sertifikalanır; 300 görev rotası ve enkaz dağılımı farklı imzalıdır.

### Koleksiyon C — Rahat üretim ve bakım

#### S09 — Kafe Vardiyası (`cafe_shift`)

- **Vaadi ve döngüsü:** Siparişleri oku, aynı anda demleme/ısıtma/hazırlama istasyonlarını yönet, doğru ürünü doğru müşteriye teslim et; stok ve tezgâh alanını taşırmadan vardiya yıldızını kazan. Şeker Konveyörü'ndeki parçaları yönlendirme oyunu değildir: oyuncu birden çok istasyondaki süre ve müşteri memnuniyetini yönetir.
- **Derinlik/zorluk:** Önce tek sipariş, sonra paralel hazırlık, özel istek, sınırlı stok ve sıra yönetimi. 7–10 öncelik ve istasyon çakışmasını; 17–20 hatasız servis zincirini, iki özel siparişi ve kontrollü stok bütçesini gerektirir.
- **Sanat/ses:** Parlak değil saten porselen, buhar ışığı, ahşap/mermer tezgâh ve temiz ürün silüetleri; sabit kamera, servis alanı altta. Espresso öğütme, fincan teması ve teslim sesi profesyonel Foley; olay başına tekrar limiti.
- **Kabul kanıtı:** Zamanlayıcı/pause adaleti, yanlış müşteriye teslim, istasyon kuyruğu, stok tükenme ve sipariş iptal sınırları; geniş dokunma alanı ve hız azaltma erişilebilir modu.

#### S10 — İç Mekân Atölyesi (`interior_studio`)

- **Vaadi ve döngüsü:** Odayı bütçe, işlev ve müşteri stil brief'ine göre döşe; ölçü/kapı/yürüme boşluğunu koru ve istenen atmosfer puanını yakala. Serbest yaratım yanında oyuncuya ölçülebilir bir tasarım hedefi verir.
- **Derinlik/zorluk:** Brief'lerde bütçe, zorunlu eşya, ışık yönü, renk ailesi, kullanım zonu ve erişilebilir geçiş kademeli artar. 7–10 iki kısıtın dengelenmesi; 17–20 küçük alanda çoklu brief ve işlevsel dolaşım ister. Puanlama gizli zevk algoritmasına dayanmaz; şartlar görünürdür.
- **Sanat/ses:** Açık plan kâğıdı, materyal örnekleri, ışık önizlemesi, sabit izometrik olmayan kamera ve seçilen eşya gölgesi. Eşya yerleşince yumuşak snap, yüzey/ kumaş için düşük seviyeli ses; rahatlatıcı ama kontrollü.
- **Kabul kanıtı:** Döndürme/yerleştirme/çarpışma, kapı-yürüme koridoru, undo/redo, safe-area, küçük ekran kontrol paleti; her brief için puan açıklaması ve birden çok geçerli tasarım çözümü.

#### S11 — Deniz Camı Akvaryumu (`tideglass_aquarium`)

- **Vaadi ve döngüsü:** Bir akvaryum kur; canlı uyumu, tank katmanları, filtre, bitki, ışık ve beslemeyi dengeleyerek huzurlu bir yaşam ortamı ve fotoğraf koleksiyonu oluştur. Sadece dekor koymak değil, görünür ihtiyaçları gözleyip sistem kurmaktır.
- **Derinlik/zorluk:** Kampanya 20 tank brifi, önce tek tür/filtre sonra uyumlu habitat, biyolojik yük, bitki ışığı ve hassas tür ekler. 7–10 su kalitesi ve komşu türleri, 17–20 sınırlı ekipmanla tam ekosistemi dengeler. Bakım kaçırma cezası/oyuncuyu geri getirme baskısı yok; çevrimdışı zaman adil ilerler.
- **Sanat/ses:** Cam kalınlığı, su kırılması ve balık gölgesi ölçülü özel çizilir; mavi, turkuaz ve bitki tonları açık fonda dinlendirici olur. Su/filtre ambiyansı kapatılabilir; canlıların refah geri bildirimi sadece renge bağlı olmaz.
- **Kabul kanıtı:** Tür uyumu ve su değer simülasyonu, pause/offline süre, erişilebilir metinle canlı durumu, kamera performansı, 300 tank challenge kombinasyonu; kaynak tüketimi uygulama kapalıyken kontrol edilir.

#### S12 — Dostlar Kurtarma Kliniği (`pet_rescue_clinic`)

- **Vaadi ve döngüsü:** Kliniğe gelen hayvanın kartındaki belirtileri incele, muayene adımını seç, uygun bakım sırasını uygula ve hayvanı güvenli biçimde iyileştir. Eğlenceli bakım simülasyonudur; gerçek veteriner teşhisi/sağlık tavsiyesi gibi sunulmaz.
- **Derinlik/zorluk:** Önce basit gözlem ve rahatlatma; sonra birden çok belirtinin doğru muayene sırası, bakım aracı ve dinlenme süresi. 7–10 yanlış işlemden dönme ve iki ihtiyaç çakışması; 17–20 zaman baskısı değil, öncelik/şefkat/ kaynak planı uzmanlığı.
- **Sanat/ses:** Özgün stilize hayvan modelleri/vektör silüetleri, yumuşak klinik beyazı, mint kumaş, detaylı ama ürkütmeyen muayene araçları. Patiler, kumaş ve klinik bildirimleri hafif Foley; hayvan sesleri seyrek ve kısa.
- **Kabul kanıtı:** Her vaka oyunun kural metninde kendi çözüm adımlarını açıklar; hata geri alınabilir, korkutucu/yaralayıcı görüntü yok; tüm vakalar uzman incelemesi ve deterministik akış testinden geçer.

### Koleksiyon D — Dünya kurma ve yönetim

#### S13 — Sahil Parkı Kurucusu (`boardwalk_builder`)

- **Vaadi ve döngüsü:** Kıyı arazisine eğlence ve hizmet yapıları yerleştir; ahşap yolları girişe bağla, ziyaretçi kapasitesini/bütçeyi dengele, her yapının çalıştığını doğrula.
- **Derinlik/zorluk:** 20 parkta artan misafir sayısı, iki eğlence noktası, yiyecek kapasitesi, temizlik ve oturma hedefleri, dar yerleşim ve sağanakta gölgelik şartı birikir. Son dört seviye 8×8 haritada çok sayıda tesis, çift servis ve bütünlüklü yol ağı ister.
- **Sanat/ses:** Sabit üstten plan görünüşü, pastel kıyı/sahil kumu, kayalık sınırları, gölgeli tesis kartları ve ahşap yol döşemeleri özel Canvas çizimidir. Sabit sahne kaydırma/zoom hatasını önler; ortak oyun sesi/sonuç sistemi korunur.
- **Kabul kanıtı:** Girişten bağlı yol ve tesis erişimi, ziyaretçi/eğlence ve yiyecek kapasitesi, bütçe, bank/atık kutusu ve sağanak-gölgelik koşulları; 20 kampanya çözüm simülasyonu, 300 seed’den bağımsız pratik park imzası, 320×600 TR ve 800×1280 EN düzeni.

#### S14 — Ay Üssü Operasyonları (`moonbase_ops`)

- **Vaadi ve döngüsü:** Modülleri bağla, enerji/oksijen/ısıyı paylaştır, ekip vardiyalarını ve acil durumları yönet; üs sakinlerini hayatta tutarken keşif hedefini tamamla. Fizik tabanlı uzay uçuşu değildir; üssün çalışan kaynak ağıdır.
- **Derinlik/zorluk:** Önce enerji, sonra oksijen/ısı ve modül kapasitesi; sonrasında meteor hasarı, gece döngüsü ve sınırlı onarım. 7–10 bir kritik sistemi kesmeden kaynak yönlendirmeyi; 17–20 arıza anında yedek planı gerektirir.
- **Sanat/ses:** Beyaz alüminyum ve mat mineral gövde, sıcak iç mekân pencereleri, açık-uyarı HUD'ı; karanlık uzay detayları gereksiz yıldız gürültüsüne dönüşmez. Düşük bas frekanslı sistem ambiyansı, alarm önceliği ve susturma seçeneği.
- **Kabul kanıtı:** Kaynak akışında döngü/taşma/negatif değer, alarm önceliği, görev kurtarılabilirliği, simülasyon hızının pause ile tutarlılığı; her seviye için başarıya ulaşan strateji sertifikası.

#### S15 — Müze Küratörü (`museum_curator`)

- **Vaadi ve döngüsü:** Koleksiyondan eser seç, sergi temasını kur, eserler arası bağları görünür kıl ve ziyaretçilerin mekân içindeki rotasını düzenle. S15 aynı müze temasını paylaşsa da S07'den ayrıdır: gizlilik değil, kalıcı sergi/ziyaretçi deneyimi kurgular.
- **Derinlik/zorluk:** Eser teması, alan, ışık hassasiyeti, ziyaretçi profili ve ödünç alma süresi artar. 7–10 sergi akışı ile koruma koşullarını; 17–20 aynı anda bütçe, ziyaretçi çeşitliliği ve küratöryel tutarlılığı ister.
- **Sanat/ses:** Kâğıt-krem galeri planı, bronz etiket, özel sergi kaidesi, ışık huzmesi ve sakin ziyaretçi silüetleri. Kart koleksiyonu okunaklıdır; ambiyans müze odası kadar sessiz, ödül sesi mütevazıdır.
- **Kabul kanıtı:** Eser tanımı/etiket taşması, yerleşim erişilebilirliği, tema puanının görünür hesaplanması, sergi koruma gereksinimleri ve birden çok iyi çözüm; çevrimdışı sergi durumu kaybolmaz.

#### S16 — Festival Yapımcısı (`festival_producer`)

- **Vaadi ve döngüsü:** Bir günlük festival için sahne akışını, sanatçı zamanlarını, enerji ve ekip vardiyasını planla; seyirciyi sahneler arasında dağıt ve gecikme/yağmur olduğunda planı uyarlayarak günü tamamla.
- **Derinlik/zorluk:** Önce tek sahne/sıra, sonra iki sahne, seyirci profilleri, sahne değişim süresi, yorgunluk ve hava olayı. 7–10 zaman çakışmalarını ve akış; 17–20 canlı sorun anında öncelikli yeniden planlamayı gerektirir.
- **Sanat/ses:** Gündüz açık etkinlik planı; sahnede sıcak ışık, kalabalık silüeti ve etkinlik rengi kontrollü. Gerçek lisanslı müzik parçası zorunlu değildir; özgün kısa ritim/ambiyans kullanılabilir, konuşma metni taşmaz.
- **Kabul kanıtı:** Zaman çizelgesi çatışması, personel/enerji, seyirci kapasitesi, hava olayı ve plan değişikliği testleri; otomatik puan nedenleri açıklanır; 300 festival senaryosu tekrarsız olur.

### Koleksiyon E — Arkadaşlarla masa/parti

#### S17 — Gizli Oda: Sosyal Çıkarım (`secret_room_party`)

- **Vaadi ve döngüsü:** 3–6 oyuncu aynı cihazı sırayla elden ele verir; her oyuncu özel rol/bilgiyi görür, ortak odadaki olayları tartışır, gizli hedefini korur ve oylama yapar. Tek oyuncuda farklı karakterlerin yönettiği kısa senaryolar oynanabilir; çevrimiçi hesap zorunluluğu yoktur.
- **Derinlik/zorluk:** Roller, herkese açık ipuçları, güvenilir/yanıltıcı bilgi oranı ve tur sayısı karıştırılır. 7–10 iki aşamalı gerekçe, 17–20 birden çok hedef/az ipucuyla sosyal okuma ister. Rol dağılımı oyun başlamadan adalet kontrolünden geçer.
- **Sanat/ses:** Işıklı ama sakin masa üstü, ayrı rol kartı çerçevesi, gizli ekran geçişinde başkalarının bilgiyi görmediğine dair perde. Ses kısa, özel bilgi okumalarında sessizlik; telefon el değiştirmesi sırasında ekranda isim/rol bırakılmaz.
- **Kabul kanıtı:** 3–6 oyuncu rol dengesi, ekran gizliliği, yeniden dağıtım/oyun bitişi, erişilebilir rol okuma ve 300 vaka/rol kombinasyonu tekillik ve adalet testi.

#### S18 — Zar ve Hançer (`dice_bluff_arena`)

- **Vaadi ve döngüsü:** Kendi kapalı zar sonucunu bil, ortak masadaki toplam hakkında iddia yükselt veya meydan oku; risk/olasılık/oyuncu davranışını okuyup turu kazan. Zar atışı kozmetik değil; olasılık ve bluff kararının kaynağıdır.
- **Derinlik/zorluk:** Zar sayısı, özel sembol ve bir defalık güvenli yeniden atış beceriyle açılır; bahis baskısı gerçek para/ödül değildir. 7–10 olasılık eşiği ve rakip profili, 17–20 rakibin geçmiş iddialarını hatırlama ile risk yönetimi ister.
- **Sanat/ses:** Ağırlığı hissedilen seramik/metal zar, keçe masa, zar kulesi ve açık iddia geçmişi. Zar sesi kısa varyasyonlu ve tekrar sınırlandırılmış; bildirim/haptik kapatılabilir.
- **Kabul kanıtı:** Olasılık ve iddia çözüm kuralı testleri, aynı turda çıkış/yeniden başlama, botların bilgi sızıntısı yapmaması, 300 zar/rol dizisinin tekilliği; rastgeleliğin adil dağılım raporu.

#### S19 — Sinyal Ortağı (`signal_pair`)

- **Vaadi ve döngüsü:** İki oyuncu ortak bir tesisi çalıştırır; bir oyuncu kontrol panelinin durumunu görür, diğeri haritanın/tehdidin bilgisini görür. Yasak kelime ve kısa iletişim penceresi içinde tarif edip birlikte doğru anahtarları/zamanlamayı seçer. Oyun bilgi paylaşımı üzerine kurulur, tek kişilik dikkat testi değildir.
- **Derinlik/zorluk:** İletişim süresi, sinyal gürültüsü, sistem sayısı ve asimetrik bilgi artar. 7–10 oyuncular rol değiştirip yanlış anlaşılmayı toparlar; 17–20 iki paralel sistemi konuşarak ve arıza önceliğiyle yönetir. Tek cihaz pass-and-play ve aynı ekrana iki kontrol seçeneği tasarlanır.
- **Sanat/ses:** İki ayrı ama aynı tasarım dilinde panel, büyük geometrik durum sembolleri, çizgi/ikon/desenle çift kodlama. Ses kapalıyken titreşim değil görsel sinyal; iletişim sırası ve kalan zaman daima okunur.
- **Kabul kanıtı:** 2 oyuncu akış testi, bilgi sızıntısı yok, rol değişiminde state korunur, küçük ekran çift kontrol çakışması çözülür; bütün görevler insanlarla denenir ve en az iki geçerli iletişim yolu sunar.

#### S20 — Kart Ocağı Düellosu (`deckforge_duel`)

- **Vaadi ve döngüsü:** Küçük desteden kart seçip kaynak harca; savunma/açık verme/kombo sırasını rakibin görünür niyetine göre kur. Mevcut kart eşleştirme hafızası değildir; sıra tabanlı taktik kart dövüşüdür. Tek oyuncu AI rakibe karşı, yerel iki oyuncu pass-and-play seçeneği.
- **Derinlik/zorluk:** 20 rakip karşılaşması, 3 kart arketipi, açık telegraph ve sınırlı enerji havuzu ile ilerler. Deste 10 kart türünden 18 kart içerir; oyuncu ve rakip desteleri ayrı tutulur. 7–10 kart sırası/karşı hamle, 17–20 arketip sinerjisini ve kaynak disiplinini sınar. Rastgele ödeme kutusu veya ödeme tabanlı güç yoktur.
- **Sanat/ses:** Mat kart dokusu, özel çerçeve ikonları, vuruş anında kısa katmanlı animasyon ve sabit savaş alanı; 3D kart çevirme zorunlu değil. Her kartta metin taşması, açıklama paneli ve durum ikonları test edilir.
- **Kabul kanıtı:** Sıra/enerji/hasar/koruma ve durum etkisi motoru, yalnız kendi kapalı elini kullanan deterministik AI, galibiyet-kayıp/yeniden maç, kart metni sığması, denge simülasyonu ve 300 rakip el/arena bileşimi tekillik testleri.

## 7. Her oyun için aynı uygulama sırası

Her S01–S20 sprintinde aşağıdaki 14 kapı sırayla uygulanır. Bir oyun doğrulama kapısını geçmeden sonraki oyunda katalog/menü entegrasyonuna başlanmaz; ortak görsel ve ses sisteminde yapılan değişikliklerde önce tüm önceki oyunların regresyonu koşar.

1. Katalog/kimlik çakışma taraması, sahiplik alanı ve mevcut oyunlara dokunulmayacak dosya listesi.
2. Oyun tasarım özeti, kurallar, kazanma/kaybetme, pause/retry ve birincil kontrol prototipi.
3. 20 kampanya planı, zorluk grafiği, 7–10/17–20 uzmanlık farkı ve tekrar senaryosu üretici tasarımı.
4. Görsel sınıf moodboard'u, sahne/hiyerarşi bloklaması, HUD-wireframe, materyal/ışık ve hareket denemesi.
5. İçerik/seed/tekillik imzası, çözüm/erişilebilir hedef ya da adil performans sertifikası.
6. Oyun motoru/kural/senaryo katmanı; arayüzden bağımsız test edilebilir model.
7. Dokunma/gesture, input buffer, hedef alanı, yanlışlıkla eylem/geri alma ve erişilebilir alternatif.
8. Sahne render'ı; sabit kamera, responsive alan, güvenli bölge, HUD ve loading/empty/error durumları.
9. Seviye ilerleme, öğretici, ipucu gerekiyorsa adil kullanım, pause/lifecycle ve ayrı save prefix.
10. Oyun sesi ve haptik; mevcut servis/event profiline ekleme, sessiz ve reduced-motion davranışı.
11. Ortak bölüm sonucu, yıldız/puan/ödül, tekrar ve hub'a dönüş; var olan tebrik sistemini koruma.
12. Unit/kural/simülasyon/seed testleri; ilk 300 içerik benzersizlik ve kampanya eğrisi sertifikası.
13. 320×600 TR + 800×1280 EN görsel/interaction testi; hatalı kelime, taşma, kaydırma ve kontrast düzeltmesi.
14. Statik analiz, ilgili tüm oyun regresyonu, düşük cihaz/performance smoke, değişiklik özeti ve sprint kapatma raporu.

## 8. Sprint sıralama, risk ve yayın ölçütü

- S01–S04 spor hissi ve gerçek zamanlı input/fizik temelini; S05–S08 aksiyon/AI/yol simülasyonunu; S09–S12 rahat üretim/ekonomi durumunu; S13–S16 çok aktörlü yönetim simülasyonunu; S17–S20 pass-and-play, rol gizliliği ve kart/zar kurallarını kanıtlar.
- Her koleksiyonda ilk oyun teknik dikey dilimdir. Onun oyun alanı, HUD ve test düzeni başarıyla doğrulanmadan aynı sınıftaki diğer oyunlar klonlanmaz. Benzer altyapı paylaşılır; görsel kimlik ve oyuncu döngüsü paylaşılmaz.
- S05, S06, S13, S14, S17, S19 ve S20 kapsam riski yüksek oyunlardır; önce küçük oynanabilir prototip ve test kanıtı gerekir. Prototipte kontrol hissi veya çözülebilirlik tutmazsa kapsam daraltılır ya da aday değiştirilir; kalite standardı düşürülmez.
- Her sonraki sprint için kademeli görünürlük/feature flag değerlendirilir; mevcut oyun kimlikleri ve tamamlanmış oyun kayıtları değiştirilmez. Mevcut 79 oyunun ardından S01–S19 ayrı kimliklerle 80.–98. oynanabilir girişler olarak eklendi.
- S20 sonrasında mağaza/yayın adayı için: 20 oyunda ortak kalite checklist'i, kategori bulunabilirliği, cihaz performansı, lisans denetimi, kayıt migrasyonu (gerekirse), gizlilik/çevrimdışı davranış, uygulama boyutu, erişilebilirlik ve tam proje regresyonu raporlanır. Bu plan tek başına herhangi bir APK'nın hazır ya da testlerin geçmiş olduğu anlamına gelmez.

## 9. Sprint ilerleme kaydı

- 5 keşif koleksiyonu, 20 farklı oyun vaadi ve ortak kalite kapıları tanımlandı; önceki Eğlence 20 serisindeki oyunlar yeniden kullanılmadı.
- **S00 — temel hazırlık:** sprint kapsamı, sınıf/oyun çakışma denetimi ve ortak entegrasyon sözleşmesi hazır. Tüm oyunlar için ortak ürün/cihaz regresyon tabanı ayrıca yayın öncesi tamamlanacak.
- **S01 — Drift Ligi dikey dilimi:** oyun ayrı sayfa, 20 kampanya seviyesi, bağımsız ilerleme anahtarı, kendine özgü açık pist/HUD çizimi, direksiyon-fren-el freni, drift puanı, checkpoint, pause ve ortak sonuç akışıyla uygulandı; katalog ve ana sayfaya eklendi.
- **S01 doğrulama:** 20 kampanya rotasının tamamlanabilirliği; 300 ayrı pratik rotanın imza tekilliği; 320×600 Türkçe telefon, 800×1280 İngilizce tablet; katalog testi; bütün oyun hub'larının küçük telefon/tablet duman testi ve 11 dosyada statik analiz geçti.
- Kampanya simülasyonu, noktasal checkpoint kontrolünün oyuncuyu aynı çizgiyi tekrar tekrar kaçırmaya zorlayabildiğini gösterdi. Checkpoint artık yalnız dar bir merkeze değmeyi değil, pist üzerinde doğru yönde kapı düzlemini geçmeyi doğruluyor; 20 bölüm otomatik sürüş çizgisiyle tamamlandı.
- **S02 — Masa Tenisi Rallisi dikey dilimi:** 20 maç seviyesi, ayrı kayıt alanı, 300 farklı pratik maç planı, gecikmeli/sınırlı hareket eden rakip, sürüklemeli raket konumu, zamanlamalı temas ve üst spin/kesme/blok vuruşlarıyla katalog ve ana ekrana eklendi. Ahşap kenarlı teal masa, katmanlı gölge/ışık, top izi, skor HUD'ı, duraklatma ve ortak maç sonucu kullanılıyor.
- **S02 doğrulama:** 20 maç ayarlarının zorluk eğrisi, 300 maç imzası, bütün 20 seviyeyi kazanan deterministik oyuncu çizgisi, rakip hareket sınırı, temas/kaçırma, 320×600 Türkçe telefon, 800×1280 İngilizce tablet, katalog ve bütün oyun hub'larının telefon/tablet duman testi geçti.
- **S03 — Penaltı Zihin Oyunu dikey dilimi:** iki rolde oynanan 20 seri, ayrı ilerleme anahtarı, 300 tekil atış dizilimi, şut köşesi/gücü ve kaleci dalış zamanı eklendi. Rakip şutunda omuz-kalça-destek ayağı ipuçlarının çoğunluğu yönü doğru gösteriyor; üst seviyelerde yalnız bir işaret yanıltıcı. Özel saha/kaleci çizimi, kayan zaman penceresi, rozetli lane seçimleri, duraklatma ve ortak sonuç akışı kullanılıyor.
- **S03 doğrulama:** 20 seviyenin artan hız/daralan karar penceresi, ipucu çoğunluğunun adilliği, 300 imza tekilliği, iki rol için kazanılabilir kampanya simülasyonu, kaçırılan zaman penceresi, 320×600 Türkçe telefon, 800×1280 İngilizce tablet, katalog ve bütün oyun hub'larının telefon/tablet duman testi geçti.
- **S04 — Air Hockey Arena dikey dilimi:** Disk fiziği, sınır/sekme tamponları, hareketli raketler ve karşı rakip, her puanda bir kez kullanılabilen güçlü smaç, yüzey türü, 20 maçlık kampanya ve 300 benzersiz pratik arena eklendi. Oyun ayrı ilerleme kimliğiyle katalog/ana ekrana bağlandı; açık teal buz sahası, metalik masa rayları, fizik izli disk, skor HUD'ı, duraklatma ve ortak maç sonucu kullanıyor.
- **S04 doğrulama:** 300 pratik alan imzası tekil; fiziksel temas/smaç, tampon ve kenar sekmesi, rakip hareket sınırı ve deterministik oyuncu stratejisiyle 20 maçın kazanılabilirliği test edildi. 320×600 Türkçe telefon, 800×1280 İngilizce tablet, katalog ve tüm oyun hub'larının telefon/tablet duman testi geçti; 9 hedefli dosyada statik analiz temiz.
- **S05 — Kalıntı Seferi dikey dilimi:** Üç odalı taktik aksiyon döngüsü; düşman saldırı telegraph'ı, dört yönlü konum alma, hedefe dokunarak nişan, yönlü saldırı/kaçınma/alan kalıntısı ve oda arası iki seçenekli pasif yükseltme eklendi. Nöbetçi, takipçi, menzilli düşman ve 7+ seviyede son oda koruyucusu; tuzak, blok ve çıkış koşulu bulunuyor. Özgün taş oda/karakter düşman illüstrasyonu, sağlık-enerji HUD'ı, ayrı ilerleme anahtarı, ortak ses/sonuç akışı ve katalog/ana ekran bağlantısı kullanılıyor.
- **S05 doğrulama:** 20 kampanya zorluk/tehdit kompozisyonu ve 300 tekrarsız deterministik sefer imzası; ilk hamlede işaretli tehdit; hareketle saldırı hattından kaçınma, dodge i-frame/cooldown, yönlü vuruş, alan becerisi, çıkış ve iki kalıntı seçimi test edildi. 320×600 Türkçe telefon, 800×1280 İngilizce tablet, katalog ve tüm oyun hub'larının telefon/tablet duman testi geçti; 9 hedefli dosyada statik analiz temiz.
- **S06 — Fener Savunması dikey dilimi:** Yolu iki kıyı koluna ayıran altı yapı noktası, dalga öncesi balista/ayaz/havan seçimi, dalga sırasında otomatik hedefleme, kule yükseltmesi/hedef önceliği, altın ödülleri ve sınırlı fener darbesi eklendi. Runner, zırhlı, süzülen, ağır ve boss düşmanlar; 20 nöbet boyunca 4–8 artan dalga ve 300 tekil pratik harita içeriyor. Açık kıyı/sahil haritası ve fener çizimi, kule menzil ovalleri, sağlık-altın HUD'ı, pause, ortak sonuç/ses ve ayrı ilerleme kaydıyla ana ekrana bağlandı.
- **S06 doğrulama:** 20 nöbetin dalga/zırh/boss eğrisi, 300 deterministik benzersiz rota+düşman manifesti, iki dalın düşman dağılımı, kule maliyeti/yükseltmesi/önceliği, fener darbesi ve iki farklı kule rolüyle ilk dalganın tutulması test edildi. 320×600 Türkçe telefon, 800×1280 İngilizce tablet, kule kurma/yükseltme/pause akışı, katalog ve tüm oyun hub'larının telefon/tablet duman testi geçti; 9 hedefli dosyada statik analiz temiz.
- **S07 — Müze: Gece Vardiyası dikey dilimi:** S05'ten farklı olarak çatışma yok; sıra tabanlı gizlilik ve kaçış oyunu. Oyuncu görünür koniler/devriye ve zamanlı lazerler arasında gölge hücrelerinde bekleyip eserleri alıyor; tek dikkat dağıtıcı devriyeyi kısa süreli saptırıyor. 20 seviye, 300 deterministik pratik galeri, bağımsız ilerleme, özel krem/taş/bronzu gölge ve lazer durumlarıyla ayıran 10×9 sahne, yön pedi, HUD, ortak ses/tebrik/sonuç ve katalog/ana ekran bağlantısı eklendi.
- **S07 doğrulama:** Bütün 20 seviye için en az bir gölge koridoru üzerinden tam eser toplama ve çıkış simülasyonu; aktif lazere girince alarm; 300 harita tekilliği/tekrar üretilebilirliği; sınır-duvar-tek kullanımlık dikkat dağıtıcı kuralları; 320×600 Türkçe telefon ve 800×1280 İngilizce tablet kontrolleri geçti. Katalog testi, tüm oyun hub'larının iki ekran boyutundaki duman testi ve 9 hedefli dosyada statik analiz temiz.
- **S08 — Derin Akıntı dikey dilimi:** Sürekli yön girdili mini denizaltı sürüşü, hız/akıntı etkisi, sonar taraması, enkazı yakın menzilde kavrama ve üsse kenetlenme eklendi. Akıntı, kaya sırtı teması, basınç derinliği, gövde, oksijen, batarya ve kargo yükü aynı motor içinde; 20 dalışta kargo 1→4 parçaya, akıntı 1→5 alana yükseliyor. Derin mavi saten su/caustic çizgileri, katmanlı deniz tabanı, kayanın hacimli çizimi, sonar halkası ve özel denizaltı illüstrasyonu, başparmak yön pedi, ölçer HUD'ı, ayrı ilerleme, ortak ses/tebrik/sonuç ve 87. oyun girişi eklendi.
- **S08 doğrulama:** Her kampanya görevinde bütün kargoyu sonar ile bulup toplamayı ve güvenli biçimde üsse dönmeyi oynatan deterministik simülasyon; kaynak tükenmesi, kaya teması, sonar bekleme/yük menzili/kenetlenme önkoşulları; 300 farklı görev imzası; 320×600 Türkçe telefon ve 800×1280 İngilizce tablet akış testleri geçti. Katalog testi, tüm oyun hub'larının iki ekran boyutundaki duman testi ve 9 hedefli dosyada statik analiz temiz.
- **S09 — Kafe Vardiyası dikey dilimi:** Espresso, çay, latte, kakao ve tost siparişlerinin öğütücü/espresso/kettle/ızgara/süt/sonlandırma istasyonlarında paralel hazırlanması; tarif ekleri, stok, müşteri sabrı ve bahşiş yönetimi eklendi. Özel çizilmiş krem-sage-ahşap kafe sahnesi, sabit (kaydırmasız) tezgâh, geniş istasyon hedefleri, ayrı `cafe_shift` kaydı, ortak ses/sonuç ve ana ekranın 88. oyunu.
- **S09 doğrulama:** 20 vardiyanın deterministik istasyon çizelgesiyle tamamlanması, yanlış/yoğun istasyon ve hazır olmadan teslim kısıtları, müşteri sabrı/kaçırma eşiği ve 300 benzersiz-tekrar üretilebilir vardiya; 320×600 TR/800×1280 EN ekran testleri geçti. Katalog testi, iki ölçüde tüm oyun hub'ı duman testi ve 9 hedefli dosyada statik analiz temiz. Telefon HUD'ında bulunan 23 px taşma kaldırıldı; bahşiş kısa gösterime çevrildi ve servis metni sığacak şekilde kısaltıldı.
- **S10 — İç Mekân Atölyesi dikey dilimi:** Oda brief’i, görünür bütçe, stil/renk hedefi, pencere ve giriş hücreli 7×7/8×8 oda; yedi özgün mobilya biçimi ve 90° döndürme, grid yerleştirme/kaldırma, çakışma ve bütçe denetimi, geri al/yeniden yap, pencere ışığı ve kapıdan erişilebilir dolaşım puanlaması eklendi. Krem parke, duvar çerçevesi ve keten/adaçayı/kiremit mobilya paletleri Canvas üzerinde çizilir; ayrı `interior_studio` ilerlemesi ve ortak ses/tebrik/sonuçla 89. oyun olarak kataloğa bağlandı.
- **S10 doğrulama:** 20 kampanya brief’inin artan 3→7 zorunlu eşya kompozisyonu ve deterministik geçerli yerleşim simülasyonu; 300 farklı oda düzeni imzası (yalnızca seed değil); sınır/çakışma/kapı/bütçe, stil/renk uyumu ve undo/redo; 320×600 TR ve 800×1280 EN UI testleri geçti. Katalogdaki 112 benzersiz sıranın ve 89 oynanabilir oyunun doğrulanması, iki boyutta tüm oyun hub'ı duman testi ve 9 hedefli dosyada statik analiz temiz.
- **S11 — Deniz Camı Akvaryumu dikey dilimi:** Lebistes/tetra/çöpçü/karides/betta/japon balığı/salyangoz türleri; grup büyüklüğü, sıcaklık aralığı, tank hacmi, biyolojik yük/filtre kapasitesi, oksijen/bitki, ışık ve taban uyumu olan habitat kurma döngüsü eklendi. Her canlı türü görünür sayaca ve erişilebilir durum metnine sahip; açık cam, katmanlı turkuaz su, kum tabanı, bitki ve balıklar Canvas'ta çiziliyor. Bağımsız `tideglass_aquarium` kaydı ve ortak ses/tebrik/sonuçla 90. oyuna bağlandı; gerçek süreye bağlı açlık veya oyuncuyu uygulamaya döndürme baskısı yok.
- **S11 doğrulama:** 20 kampanya tankında uyumlu sürü ve ekipman konfigürasyonu ile çözüm simülasyonu; uyumsuz betta/japon balığı karışımı, su sıcaklığı, litre/bioload/filtre, oksijen ve seed’den bağımsız 300 ayrı habitat düzeni; 320×600 TR ve 800×1280 EN UI testleri geçti. Katalogda 113 benzersiz kimlik/sıra ve 90 oynanabilir oyun doğrulandı; bütün oyun hub'larının iki ölçüde duman testi ile 13 hedefli dosyada statik analiz temiz.
- **S12 — Dostlar Kurtarma Kliniği dikey dilimi:** Kedi/köpek/tavşan/papağan için sakin oda, su, havlu, nazik fırça, temiz yatak, sakin oyun ve dinlenme adımlarını gözlem ipuçlarına göre sıralama eklendi. Hatalı istasyon seçimi ilerlemeyi silmez; oyuncu ipucunu yeniden okuyup devam eder. Özgün pastel klinik/hayvan Canvas çizimi, 20 vakada 3→7 adımlı artış, tekrar girişte ayrı 300 vaka dizisi, `pet_rescue_clinic` kaydı, ortak ses/tebrik/sonuç ve 91. katalog kartı tamamlandı. Ekranda açıkça veteriner tavsiyesi olmadığı belirtilir.
- **S12 doğrulama:** 20 vaka dizisinin sıra ile tamamlanması, yanlış adımda ilerlemenin sabit kalması, 300 seed’den bağımsız farklı ziyaret planı, Türkçe 320×600 ve İngilizce 800×1280 UI testleri geçti. Katalogda 114 benzersiz sıra/kimlik ve 91 oynanabilir oyun; tüm oyun hub'larının iki ölçüde duman testi ve 9 hedefli dosyada statik analiz temiz.
- Windows test ortamında SoLoud yerel kitaplığı yüklenmediğinde mevcut sessiz geri dönüş çalıştı. Gerçek Android cihazda ses/performans ve görsel inceleme ile yayın APK derlemesi bu doğrulama paketinin dışında kaldı.
- **S13 — Sahil Parkı Kurucusu dikey dilimi:** 7×7/8×8 sahil ızgarasında girişten devam eden ahşap yol, atlı karınca/dönme dolap, kafe, bank, geri dönüşüm, gölgelik ve lamba yerleşimi; bütçe, tesis erişimi, eğlence/yiyecek kapasitesi, temizlik/oturma ve sağanak konforu eklendi. Özel çizilmiş sabit pastel kıyı sahnesi, seçici, geri al/yeniden yap, ayrı `boardwalk_builder` ilerlemesi, ortak ses/sonuç ve 92. oyun kartı entegre edildi.
- **S13 doğrulama:** Deterministik çözümle 20 kampanyanın ve 300 pratik parkın tamamı açılabilir; seed dışı 300 yerleşim imzası tekil. Giriş/kayalık/işgal/bütçe kuralları, bağlı tesisler, kapasite, yağmurda gölgelik ve undo/redo; 320×600 Türkçe telefon ve 800×1280 İngilizce tablet testleri geçti. Katalog 115 benzersiz kayıt/92 oynanabilir oyun/33 Eğlence oyunu oldu. Bu dilim vektör/Canvas çizimidir; gerçek Unity renderer veya gerçek cihaz FPS/ses testi iddiası taşımaz.
- **S14 — Ay Üssü Operasyonları dikey dilimi:** Komuta çekirdeğine bağlı modüler ay üssünde güneş enerjisi, batarya, habitat, oksijen serası, laboratuvar, haberleşme rölesi, ısı radyatörü ve meteor kalkanı yerleşimi; enerji/oksijen/ısı bütçesi ve görev tehdidi doğrulaması eklendi. Özgün sabit ay yüzeyi/modül Canvas çizimi, geri al/yeniden yap, ayrı `moonbase_ops` ilerlemesi, ortak ses/tebrik/sonuç ve 93. oyun kartı entegre edildi.
- **S14 doğrulama:** 20 görev için ekip/kaynak/tehdit artışı ve çözüm simülasyonu; göktaşı kalkanı, tutulma bataryası, bağlı modül ağı, kaynak yetersizliği, taş/kilitli çekirdek/bütçe ve undo/redo; 300 seed’den bağımsız pratik görev imzası ve tamamlanabilirliği; 320×600 Türkçe telefon ve 800×1280 İngilizce tablet testleri geçti. Katalogda 116 benzersiz kayıt, 93 oynanabilir oyun ve 34 Eğlence oyunu var.
- **S15 — Müze Küratörü dikey dilimi:** Beş koleksiyon temasından eser seçip sıralı galeri kaidelerine yerleştirme; dönem kronolojisi, eser teması, hassas eser sınırı, ziyaretçi ilgisi ve bütçeyle sergi açma eklendi. Müze-gece gizlilik döngüsünden ve hikâye sıralama oyunundan ayrılan kalıcı sergi kurgusu; tema rengi değişen özel galeri/kaide Canvas çizimi, koleksiyon seçicisi, undo/redo, ayrı `museum_curator` ilerlemesi, ortak ses/sonuç ve 94. oyun kartıyla entegre edildi.
- **S15 doğrulama:** 20 kampanya sergisinin artan 3→7 kaidesiyle çözülebilirliği; dönem sırası, tekrar eden eseri engelleme, kırılgan eser eşiği ve undo/redo; 300 benzersiz tema/koleksiyon/ziyaretçi/bütçe planı ve çözüm doğrulaması; 320×600 TR ve 800×1280 EN UI testleri geçti. Katalogda 117 benzersiz kayıt, 94 oynanabilir oyun ve 35 Eğlence oyunu var.
- **S16 — Festival Yapımcısı dikey dilimi:** İki sahneli, sekiz zaman bloklu programda 14 ayrı performans türünü yerleştirme; tür çeşitliliği, zaman pencereleri, sahne dönüş aralığı, yağmur koruması, kalabalık/ekip/enerji ve bütçe dengesi eklendi. Özel festival takvimi Canvas sahnesi, sabit ölçülü setlist, undo/redo, ayrı `festival_producer` ilerlemesi, ortak ses/tebrik/sonuç ve 95. oyun kartıyla entegre edildi.
- **S16 doğrulama:** 20 kampanyanın 3→8 performansla planlanması, aynı sahne/zaman çakışması, zaman penceresi, sahne dönüş aralığı, yağmur ve kaynak sınırları; 300 seed’den bağımsız benzersiz festival planı ve çözülebilirlik; 320×600 Türkçe telefon ve 800×1280 İngilizce tablet setlist/yerleşim testleri geçti. Katalogda 118 benzersiz kayıt, 95 oynanabilir oyun ve 36 Eğlence oyunu var. Festival ve müze koleksiyon ekranlarının tablet genişliğinde satır gizleme sorunu sabit hücre ölçüsüyle giderildi.
- **S17 — Gizli Oda: Sosyal Çıkarım dikey dilimi:** 3–6 oyuncu için aynı cihazda elden ele özel rol kartı, sabotajcı/araştırmacı hedefleri, açık vaka kanıtları, tartışma ve sırayla kapalı oy akışı eklendi. Rol kartı kapatılınca ekrandan kaldırılır; oylar son oyuncu oy verene kadar görünmez. Tek sabotajcı, çoğunluk eşiği ve beraberlikte kaçış kuralı, farklı delil havuzlu 20 kampanya vakası, 300 tekil pratik vaka, özel masaüstü/vaka Canvas çizimi, ayrı `secret_room_party` ilerlemesi, ortak ses/sonuç ve 96. oyun kartıyla bağlandı.
- **S17 doğrulama:** 3–6 kişide adil tek sabotajcı/oy eşiği, 20 kampanya zorluk eğrisi, 300 deterministik/benzersiz rol-vaka kombinasyonu; gizli rolün sıradaki oyuncuya geçerken kaybolması, kendine oy verememe, oyların son pusulaya kadar gizli kalması, beraberlik ve sabotajcıyı yakalama; 320×600 Türkçe telefon ve 800×1280 İngilizce tablet akışları geçti. Katalogda 119 benzersiz kayıt, 96 oynanabilir oyun ve 37 Eğlence oyunu var.
- **S18 — Zar ve Hançer dikey dilimi:** Bilgisayara karşı ve yerel iki oyuncu modunda kapalı zar eli; adet/yüz sıralı yasal iddia, olasılık okuyarak yükseltme veya meydan okuma, yıldız jokeri ve el sonunda zarların açılması eklendi. Bilgisayar kararları yalnızca kendi zarlarını, ortak teklifi ve açıklanmış masa kurallarını kullanır; insan zarına meydan okumadan önce erişemez. 20 arenalı 3→7 zar kampanyası, 300 tekil pratik el, özgün keçe masa/zar Canvas çizimi, ayrı `dice_bluff_arena` ilerlemesi, ortak ses/sonuç ve 97. oyun kartıyla entegre edildi.
- **S18 doğrulama:** 20 kampanyada zar adedi/yüz/joker kademesi; 300 deterministik ve yapısal olarak benzersiz el; geçersiz/yasal teklif sırası, joker sayımı, doğru/yanlış meydan okuma, bilgisayarın gizli eli kullanmaması ve sonuçta iki elin açılması; 320×600 Türkçe telefon ve 800×1280 İngilizce tablet akışları geçti. Katalogda 120 benzersiz kayıt, 97 oynanabilir oyun ve 38 Eğlence oyunu var.
- **S19 — Sinyal Ortağı dikey dilimi:** Aynı cihazda iki gerçek oyuncunun asimetrik bilgiyle haberleştiği Gezgin/Operatör röle oyunu eklendi. Gezgin 3→8 darbeli gizli rotayı görüp cihazı devrediyor; özel rota ekrandan kaldırılıyor. Operatör farklı kablo sırasını gören panelde dört sinyalden rotayı kuruyor; hatalı aktarım ortak başlangıç eşleşmesini bildiriyor ve ekip tekrar deneyebiliyor. Yirmi farklı istasyon, 300 tekil rota/kablo-bandı planı, özgün röle paneli Canvas çizimi, ayrı `signal_pair` ilerlemesi, ortak ses/sonuç ve 98. oyun kartıyla entegre edildi.
- **S19 doğrulama:** 20 görevde 3→8 sinyal artışı ve farklı panel kabloları; 300 deterministik/benzersiz rota ve wiring düzeni; rol geçişinde özel rota verisinin görünmez olması, eksik/yanlış rota, doğru-prefix geri bildirimi, geri al/temizle ve başarılı röle onarımı; 320×600 Türkçe telefon ve 800×1280 İngilizce tablet düzenleri geçti. Katalogda 121 benzersiz kayıt, 98 oynanabilir oyun ve 39 Eğlence oyunu var.
- **S20 — Deste Ustası dikey dilimi:** 10 kart türü/18 fiziksel kart içeren deterministik deste; hücum, delme, siper, iyileşme, odak, karşı duruş, enerji vergisi ve kesinti etkileri; oyuncu için tur başına 3 enerji; görünen rakip niyetine göre kendi kapalı elinden plan yapan AI; bilgisayara karşı ve yerel iki oyuncu modları eklendi. Rakip enerji bütçesi ilk iki bölümde 1, 3–6. bölümlerde 2, 7. seviyeden itibaren 3'e çıkar; 7–10 uzman bandında artan can ve arketip farklılığı bu temeli zorlaştırır. Yerel mod cihaz devrinde iki tarafın elini/planını gizler; tur çözülünce seçilen kartları ve can değişimini açıklar. İlk girişte 20 ayrı arena/kampanya karşılaşması, aynı seviyenin tekrar ziyaretlerinde sıra ile 300 tekil pratik düzeni, ayrı `deckforge_duel` ilerlemesi, ortak ses/sonuç akışı, özel arena ve kart yüzü Canvas çizimiyle 99. oyun olarak katalog ve ana ekrana bağlandı.
- **S20 doğrulama:** 20 kampanya sahnesinin benzersizliği, rakip can/enerji eğrisi ve eğitim bandındaki 6 seviyeyi kazanan deterministik taktik stratejisi; aynı seed ile yeniden üretilebilen 300 yapısal olarak farklı pratik düzen; enerji aşımı, tur geçme, eşzamanlı hasar, 12 tur sınırı, eşit yerel başlangıç canı, kapalı el/plan gizliliği ve AI'nin oyuncu planından bağımsız kararı test edildi. Aynı seviyeyi tekrar açınca pratik #001'e geçiş, 320×600 Türkçe telefon pass-and-play devri ve 800×1280 İngilizce bilgisayar maçı doğrulandı. Katalogda 122 benzersiz kimlik/sıra, 99 oynanabilir giriş ve 40 Eğlence oyunu var; oyun merkezi telefon/tablet duman testi de geçti.
- **S01–S20 uygulama tamamlandı.** Tam proje regresyonu 920/920 testle geçti; katalog sayısı beklentisi yeni 99 oynanabilir girişi yansıtacak biçimde güncellendi. Sonrasında lint temizliği yapılan ortak dosyalar ve katalog sözleşmesi için 18/18 hedefli test geçti; `flutter analyze --no-pub` sıfır bulguyla tamamlandı.
- Android release APK'sı `build/app/outputs/flutter-apk/app-release.apk` konumunda üretildi (94.5 MiB; `com.mustafapolat.zeka_parkuru`, 1.8.6+22; SHA-256 `FE065EBCBC998D8D615C461D141AB4E6C8EBAED5473507BD666D619B456C574B`). `apksigner` doğrulamasında APK V2 imzası geçerli. Bu sürüm telefona kurulmadı; kayıtlı üretim uygulaması ve kullanıcı verileri korundu.
- Bu oyunlar Flutter widget/Canvas çizimleridir; “Unity motorunda render edildi” anlamına gelmez. Test cihazı dışında gerçek Android cihazda son görsel/ses/FPS ve etkileşim denetimi ayrıca yapılmalıdır; APK derlemesi cihaz üzerinde oynanış veya yayın mağazası onayı kanıtı değildir.
