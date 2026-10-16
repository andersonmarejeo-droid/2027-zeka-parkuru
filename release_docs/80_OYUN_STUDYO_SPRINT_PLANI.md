# Zekâ Parkuru — 80 Oyun Stüdyo Sprint Planı

> **Sürekli çalışma yetkisi:** Ürün sahibi, bu plandaki görsel düzen, oyun geliştirme, test, hata düzeltme ve APK üretim adımlarının kesintisiz yürütülmesi için önceden onay vermiştir. Mevcut oyun verisini silen, dışarıya yayınlayan veya geri döndürülemez işlem gerektiren bir durum dışında ek onay beklenmez.

Bu belge, mevcut 11 oyunu koruyarak toplam 80 oyuna ulaşmanın üretim sözleşmesidir. İlk 11 sprint **mevcut oyunların kurallarını değiştirmez**; yalnızca görsel, erişilebilirlik, performans ve kalite sertleştirmesi yapar. Geriye kalan 69 oyun özgün ad, görsel dünya, seviye verisi ve ses kimliğiyle eklenir.

## Best 20 canlı durum eki

- Tamamlandı: S09 **Ok Rotası**. Görünür ok ışınlarının oluşturduğu bağımlılık grafı her hamleden sonra güncellenir; yalnızca yolu açık ok kaldırılabilir. 20 kampanya ve ilk 300 tekrar tahtası benzersiz imzalı ve gerçek kuralla oynatılan çözüm sırasıyla sertifikalıdır. 5×5–8×8 kontrollü yoğunluk artışı, geri al, doğrulanmış ipucu, engelleyici oku gösteren hata geri bildirimi, açık seramik/ink görsel sınıfı, ayrı ilerleme ve ortak sonuç/tebrik akışı tamamlandı. 320×600 telefon, 800×1280 tablet ve katalog/öneri doğrulandı; proje genelindeki son regresyonda 311 test geçti. Sıradaki S10: **Satranç Matı**.
- Tamamlandı: S10 **Satranç Matı**. `mini_chess_tactics` kataloğu ve ilerleme anahtarı korundu; uygulama içi satranç motoru yasal hamle, şah emniyeti, rok, geçerken alma, dört terfi seçeneği ile mat/pat ayrımını kapsar. 20 kampanya ve ilk 300 tekrar tahtası farklı imzalı; her konumda tek yasal anlık mat hamlesi, tüm aday hamleleri deneyen sertifika ile doğrulanır. Seviye zorluğu 3–14 asgari yasal aday hamlesine ve 3–7 taşlı etüt yoğunluğuna göre yükselir. Seçim/hedef kareleri, yanlış yasal hamle geri bildirimi, iki aşamalı ipucu, aynı etüdü sıfırlama, 320×600 telefon ve 800×1280 tablet açılışı, strateji sınıfı ses profili, sonuç akışı ve ana menü/öneri bağı tamamlandı. Statik analiz temiz; proje genelindeki **320 test** başarılı. Sıradaki: S11 Döngü Ustası.
- Tamamlandı: S11 **Döngü Ustası**. Çözücü hücre sayılarını, ızgara köşe derecelerini ve tek bağlı döngü şartını birlikte kontrol eder; 20 kampanya + 300 pratik haritası benzersiz ve tek çözümlüdür. Doğrulanmış ipucu, kural dışı çizgiyi reddetme, erken halka koruması, undo/reset, açık seramik tahta ve `loop_master` bağımsız ilerleme anahtarı tamamlandı.
- Tamamlandı: S12 **Go Yaşam-Ölüm**. Taş grubu/özgürlük motoru yakalama, intihar yasağı, basit ko ve pas kuralını uygular; “işaretli grubu yakala/kurtar” içeriklerinde tek yasal yaşamsal hamle sertifikası vardır. 20 kampanya + 300 tekrar tahtası farklı; 5×5–9×9 tahta ve çeldirici yoğunluğu bantlara göre artar. Özel taş render'ı, renk dışı hedef halka, strateji ses/sonuç düzeni ve `go_life_death` ilerlemesi tamamlandı. S11–S12 sonrası ilgili 13 kaynakta analiz temiz, tam proje regresyonunda **334 test geçti**. Sıradaki: S13 Kod Kırıcı.
- Tamamlandı: S13 **Kod Kırıcı**. Yerinde/yanlış yerde sembol geri bildirimi yinelenen renklerde frekanslarla eşlenir; 20 kampanya + ilk 300 tekrar kodu kural imzası dahil benzersizdir. Arama uzayı her zorluk bandında büyür (120 → 840 → 7.776 → 20.160 → 32.768 → 531.441 → 1.000.000 → 10.000.000), yinelenebilirlik/yuva/palet/deneme sınırı görünürdür. Renk dışı numaralı taşlar, tahmin geçmişi, geri al, kademeli doğrulanmış ipucu ve ortak sonuç/ilerleme tamamlandı. Kompakt telefon/tablet, katalog ve öneri entegrasyonu doğrulandı; analiz temiz, tam proje regresyonunda **341 test geçti**. Sıradaki: S14 Shogi Mat.
- Tamamlandı: S14 **Shogi Mat**. 9×9 Shogi yasal hamle motoru terfi/zorunlu terfi, yakalanan taşı ele alma, nifu, ölü kare, şah emniyeti ve yasak piyon-mat kurallarını uygular; tek yasal anlık mat hamlesi bütün adaylara karşı kanıtlanır. Kampanyadaki 20 etüt ve 300 tekrar senaryosu benzersiz imzalıdır; taş yoğunluğu ve aday hamle sayısı kademeli artar. 320×600 telefon/800×1280 tablet, elden taş bırakmayla sertifikalı mat çözümü, kural kenar durumları, katalog/öneri/ayrı kayıt entegrasyonu ve hedefli **26 test** geçti; analiz temiz. Tam proje regresyonunda **351 test geçti**. Sıradaki S15 **Ada ve Deniz**.
- Tamamlandı: S15 **Ada ve Deniz**. Nurikabe motoru numaralı ada büyüklüğü/bağlantısı, çapraz ada teması yasağı, tek deniz ve 2×2 su yasağını uygular; üretim şeritleri geçerli bir çözüm kurar ve exact solver tek çözümü doğrulamadan tahtayı kabul etmez. 20 kampanya + 300 pratik haritası imza çakışması olmadan üretildi; 5×5–8×8 büyüme, 7–8 ileri ve 9–10 uzman bantları, ada/deniz işaretleme, uzun basışla silme, undo, ipucu/reset, erişilebilir işlem hedefi ve ortak tebrik akışı tamamlandı. 320×600 telefon, 800×1280 İngilizce merkez, katalog/öneri, 20 hedefli test ve statik analiz temiz; tam proje regresyonunda **358 test geçti**. Sıradaki S16 **Peg Solitaire**.
- Tamamlandı: Best 20 S16 **Tek Taş (Peg Solitaire)**. Klasik 33 yuvalı İngiliz tahtasında yatay/dikey atlayışta üzerinden geçilen taş kalkar; her sertifikalı çözüm merkezde tek taş bırakır. 20 kampanya tahtası ve 300 tekrar tahtası imza çakışması olmadan üretildi; başlangıç taşı sayısı 13’ten 28’e yükselir, 7–8 ileri ve 9–10 uzman bandı ayrı etiketlenir. Seçim ve legal iniş vurgusu, ipucu/geri al/sıfırla, özel gölgeli taş yüzeyi, strateji ses profili, ortak sonuç akışı, ayrı kayıt anahtarı, katalog ve ana ekran önerisi tamamlandı. 320×600 telefon ve 800×1280 İngilizce tablet oynanışı, tüm oyun merkezi açılışı, hedefli testler ve temiz statik analiz; tam proje regresyonunda **364 test geçti**. Sıradaki Best 20 S17 **Futoshiki**.
- Tamamlandı: Best 20 S17 **Futoshiki**. Latin-kare satır/sütun benzersizliği, komşu eşitsizlik zincirleri ve MRV geri izlemeli exact solver. 20 kampanya ve ilk 300 tekrar tahtası, kanonikleştirilmiş imza ile benzersiz; her tahta tek çözüm sayısını solver düğüm bütçesi içinde kanıtlar. 4×4→5×5→6×6 geçişi, giderek seyrekleşen başlangıç değerleri ve artan ilişki sayısı; 7–8 ileri, 9–10 uzman katmanı. Sayı bankası, başlangıçları koruma, ihlal çerçevesi, ipucu/undo/reset, mobil dostu özel Canvas eşitsizlikli tablo, sayı sınıfı teması/sesi, katalog/öneri/ayrı ilerleme ve ortak sonuç akışı tamamlandı. 320×600 telefonda yanlış değer/undo/doğru çözüm, 800×1280 İngilizce hub ve tüm oyun merkezi açılışları geçti; statik analiz temiz, tam regresyon **371 testte başarılı**. Sıradaki Best 20 S18 **Hex Bağlantısı**.

- Tamamlandı: Best 20 S18 **Hex Bağlantısı**. Klasik Hex bağlantı yönleri ve altı komşulu hamle motoru; beraberlik yok, iki taraf aynı maçta kazanamaz. 20 kampanya ve 300 tekrar açılışı benzersiz, geçerli ve oyuncuya ilk hamleyi bırakır. 5×5→7×7 tahta, seviye bandında derinleşen alpha-beta rakibi; seramik/gölgeli altıgen render, bağlantı yönlerini renk ve yazıyla anlatan gösterge, dokunma/undo/hint/restart, ayrı kayıt, strateji sesi ve ortak zafer akışı tamamlandı. Telefon maçı, tablet hub, rakip karşı hamlesi, tam turu geri alma, katalog/öneri/tüm oyun merkezleri doğrulandı; Hex hedefli statik analiz temiz ve tam proje regresyonunda **380 test geçti**. Sıradaki Best 20 S19 **Gökdelenler**.
- Tamamlandı: Best 20 S19 **Gökdelenler**. Dört kenar görüş ipuçlarıyla Latin-kare satır/sütun yüksekliği kısıtları exact solver tarafından birlikte çözülür. 20 kampanya ve 300 pratik tahta benzersiz imzalı ve tek çözümlü kanıtlıdır; 4×4’ten 7×7’ye büyüyen tahta ve azalan ipucu yoğunluğu kontrollü zorluk artışı sağlar. Yükseklik bankası, çakışma vurgusu, ipucu/undo/reset, özgün açık seramik şehir görünümü, ayrı ilerleme, mantık ses profili ve ortak sonuç/tebrik akışı tamamlandı. 320×600 Türkçe telefon ve 800×1280 İngilizce tablet çözüm/hub testleri; katalog, öneri ve tüm oyun merkezi entegrasyonu geçti. Hedefli statik analiz temiz; tam proje regresyonunda **422 test geçti**. Sıradaki ve son Best 20 S20 **Hitori**.
- Tamamlandı: Best 20 S20 **Hitori**. Yinelenen satır/sütun sayıları gölgelenir; siyah hücreler kenar komşusu olamaz ve beyaz alan bağlı kalır. 20 kampanya + ilk 300 pratik tahtası benzersiz imzalı ve exact solver ile tek çözümlü doğrulanır. 5×5→8×8 tahta büyümesi ve 7→13 hedef siyah hücre yoğunluğu, ileri/uzman/usta aşamalarıyla eşleştirilir. Dokunma, geri al, ipucu, sıfırla, hücre bazında ihlal, ayrı ilerleme, sınıf sesi ve ortak sonuç/tebrik akışı tamamlandı. 320×600 telefonda 8×8 son hücreye yatay kaydırma/taşmasızlık ve 800×1280 İngilizce tablet ekranı; katalog, öneri, oyun merkezleri ve sertifikalı çözüm testleri geçti. Hedefli statik analiz temiz; S20 dâhil tam proje regresyonundaki **442 test geçti**. Best 20 serisi tamamlandı.

## Canlı sprint durumu — 28 Eylül 2026

> Best 20 kapsam düzeltmesi: oyun başına 20 seviye (seri genelinde 20 oyunla karıştırılmamalı); her oyunun ilk 20 ekranı birbirinden farklı, sabit tohumlu ve çözülebilir olmalı. Bu düzeltme Best 20 dışındaki oyunların seviyelerini ve kayıtlarını değiştirmez.

- Tamamlandı: açık Studio yüzey sistemi, 80 oyunluk sınıf kataloğu, güvenli alan/dokunma sözleşmesi, görsel kaplama, ses profili, sonuç/seed sözleşmesi ve mevcut 11 oyunun seviye merkezi görünümü.
- Tamamlandı: Best 20 S05 **Kakuro Izgarası**. 20 sabit tohumlu, tekrarsız Kakuro düzeni; tüm yatay/dikey dizilerde 1–9 rakam benzersizliği ve her tahtada tek çözüm doğrulaması. İki 10 seviyelik bölümde tahta alanı, kesişim yoğunluğu ve dizi uzunluğu kontrollü artar; 7–8 ileri, 9–10 uzman düzeyi, ikinci bölümde en az beşli dizi doğrulanır. Diyagonal toplam hücreleri, ilişkili dizilerin kalan toplamı, 1–9 tuş takımı, geri al/sil/sıfırla/doğrulanmış ipucu, yanlış hücre vurgusu, sayı sınıfı ses profili ve ortak sonuç kutlaması eklendi. Ayrı `kakuro` ilerlemesi; 320×600 telefon, 800×1280 tablet, katalog/öneri sözleşmeleri, temiz statik analiz ve tam regresyonda 287 test geçti.
- Tamamlandı: Best 20 S06 **Reversi Arenası**. Standart 8×8 kuralları, taş çevirme doğrulaması, zorunlu pas ve iki taraf da hamlesizken doğru maç sonu. Açılıştan yasal hamlelerle üretilmiş 20 deterministik/benzersiz başlangıç; sabit koyu taraf, her kök hamleye dengeli arama bütçesi veren alpha-beta rakip ve köşe/hareketlilik/kenar/cephe/oyun-sonu değerlendirmesi. İpucu, maç içi geri al, aynı senaryoyu yeniden başlat, taş/hamle göstergesi, açık Studio yüzeyleri ve dengeli felt/seramik tahta, strateji ses profili, ortak sonuç kutlaması ve bağımsız `reversi_arena` ilerlemesi. 320×600 Türkçe ve 800×1280 İngilizce ekran açılışı ile kural/kampanya testleri geçti; Kakuro/Reversi 20 seviyelik öneri ölçeği uyumlu. Tam regresyonda **293 test geçti**; son arama-bütçesi ayarından sonra Reversi ve iki ekran boyutunu kapsayan 8 hedefli test ile ilgili dosyaların statik analizi temiz. Best 20 serisi için ek kayıt; ana 80 katalog girişleri ve sıraları korunur.
- Tamamlandı: Best 20 S07 **Picross Ustası**. 20 ana seviye 5×5’ten 15×15’e büyür; ipuçları çözücüyle tek çözümlü doğrulanır. Seviye tekrarlarında cihazda kalıcı sayaç 300 ayrı, tek çözümlü pratik tahtasına geçer; 300 tahta testte çakışmasız doğrulandı. Doldur/boş işaretleri, geri al, sıfırla, doğrulanmış ipucu, yakınlaştırma ve yana kaydırma; ayrı ilerleme anahtarı, görsel sınıf ses profili ve ortak sonuç/tebrik akışı tamamlandı. 7–8 ileri, 9–10 uzman, 17–20 usta eğrisi; 320×600 Türkçe ve 800×1280 İngilizce testleri ile katalog/öneri ve tüm oyun merkezi açılışları geçti. Picross sonrasında proje genelindeki 296 test hatasız geçti.
- Tamamlandı: Best 20 S08 **Tavla Ustası**. 20 benzersiz, yasal hamle sunan maç durumu ve ilk 300 tekrar tahtası campaign konumlarıyla da çakışmayacak şekilde doğrulandı. Bar önceliği, kırma/kapalı nokta, çift zar, azami zar ve yüksek zar kuralı, pas, toplama/overshoot ve maç sonu kilidi motor testlerinden geçti. 7–8 ileri, 9–10 uzman, 17–20 olasılıklı zar karşılığı arayan usta rakip eğrisi; geri al/ipuçları/sıfırlama, kalan zar göstergesi, erişilebilir toplama hedefi, strateji sınıfı ses profili ve ortak sonuç/tebrik akışı bağlandı. 320×600 telefon ve 800×1280 tablet açılışı, katalog/öneri ve tüm oyun ekranları geçti. Tam proje regresyonu **306 testle** hatasız tamamlandı; masaüstü ses eklentisi yoksa güvenli sessiz geri dönüş çalıştı.
- Tamamlandı: S02 **Akış Bağlantısı**. Mantık sınıfına eklendi; 10 sabit ve otomatik doğrulanmış çözüm, tek parmaklı yol çizimi, kesişme engeli, ipucu/sıfırlama, sonuç akışı ve küçük ekran widget testi var.
- Tamamlandı: S03 **Devre Tamiri**. 10 kaynak-hedef devresi, karşılıklı tel bağlantısı doğrulaması, 90° dönüş, ivory devre kartı, ipucu/sıfırlama ve sonuç akışı tamamlandı. Android paketi üretildi; sonraki ürün çıtası değerlendirmesinde mevcut başlangıç etkinliği olarak sınıflandırıldı.
- Tamamlandı: Ana katalog, aktif oyunları rastgele bir kart dizisi yerine sekiz kalıcı beceri sınıfının altında gruplayacak şekilde yenilendi. Her sınıfın tek sakin vurgu rengi, aktif oyun sayısı ve planlanan içerik kotası var.
- Ürün çıtası güncellendi: hızlı/kolay oyunlar yeni içerik olarak kabul edilmeyecek. Akış Bağlantısı ve Devre Tamiri mevcut pakette başlangıç etkinliği olarak kalır; aynı tek hareketli formül yeni oyunlarda çoğaltılmaz.
- Eleme kararı: **Işın Yönlendir**, tek ışın ve ayna çevirme döngüsü yeterli derinliğe ulaşmadığı için oynanabilir ana kataloğa alınmadı. İleri optik kurallar ve çoklu hedef tasarımı tamamlanana kadar beklemede.
- Tamamlandı: S04 **Dedektif Notları**. Dört kişi/oda/eser/sıra ilişkisini birleştiren çıkarım matrisi; 300 ayrı çözüm düzeni, her vaka için tekil çözüm kontrolü, yerelleştirilmiş ipuçları, küçük ekranda kaydırma testi ve sonraki vakaya geçiş akışı doğrulandı.
- Tamamlandı: S05 **Köprü Kur**. Ada derece sayıları, en fazla iki köprü, kesişme yasağı ve tüm ağı birleştirme kuralı; dört zorluk bandı, 300 ayrı tek çözümlü tahta, çift köprü, geri al/ipuçları/sıfırlama, özel çizimli seramik-mühendislik yüzeyi ve kompakt telefon etkileşim testi doğrulandı.
- Tamamlandı: S06 **Kapı Dizisi**. Konum, sıralama, komşuluk/mesafe ve tek-çift sıra ipuçları aynı vakada birleşir; 5–8 kapılı dört zorluk bandında 300 benzersiz dizi ve tek çözüm doğrulandı. Kasa illüstrasyonu kodla çizildi; seçili konum, taş değişimi, geri al, boşaltma, ipucu ve sonuç akışı; 320 dp telefon çözümü ve İngilizce tablet açılışı test edildi.
- Tamamlandı: S07 **Park Yeri**. Ray-kısıtlı 6×6 araç planlaması, 300 benzersiz ve en kısa çözümü BFS ile doğrulanmış tahta, onlu paketlerde 7–8 ileri ve 9–10 uzman zorluğu tamamlandı. Özel çizilmiş asfalt/park çizgisi/araç yüzeyi; hücre boyutunda dokunma alanı, sürükleme önizlemesi, ipucu, geri alma, sıfırlama, ilerleme kaydı ve ortak sonuç/ses profili bağlandı. 320×600 telefon ve 800×1280 İngilizce tablet testleri geçti.
- Tamamlandı: S08 **Kilit Aç**. Beş–sekiz pimli, dört çentik değerli 300 deterministik kilit; pim toplamı, yerel yükseklik ilişkileri, dizisel ve toplu kontrol sinyalleriyle tekil çözüme bağlanır. Her onlu pakette ek destek ipuçları 9’dan 0’a düşer; 7–8 ileri, 9–10 uzman kademesidir. Özel çizilmiş açık emaye kilit yüzeyi, satır bazlı durum simgeleri, 48 dp pim seçimi, ipucu/geri al/sıfırla ve ortak mantık ses/tebrik akışı tamamlandı. 320×600 Türkçe oynanış/çözüm, 800×1280 İngilizce harita ve mevcut oyunların açılış testleri geçti.
- Tamamlandı: Best 20 S03 **Mayın Dedektifi**. 20 benzersiz mayın alanı; 3×3 güvenli açılış, komşuluk sayıları, sıfır alanı açılımı ve doğrudan/alt-küme çıkarımlarıyla tahminsiz çözüm sertifikası. Her 10'lu pakette 7–8 ileri, 9–10 uzman kademeleri test edilir. Mantık sınıfı seramik tahta, dokunma/işaret modu, ipucu/geri al/sıfırla, ortak ses ve sonuç akışı; 320×600 telefon ve 800×1280 İngilizce tablet açılışı doğrulanır. 20 içerik benzersizlik/çözülebilirlik testi, telefon çözüm akışı, katalog/ana ekran sözleşmesi ve tüm oyun merkezi açılış testleri geçti.
- Tamamlandı: Best 20 S04 **Depo Ustası**. 20 deterministik ve tekrarsız Sokoban tarzı düzen hedeflerden geriye yasal itişlerle üretilir; push-space BFS en az itiş sayısını kanıtlar, oyuncunun yürüme rotası ayrıca çıkarılır ve hamle sertifikası baştan sona oynatılır. Her onlu pakette 7–8 ileri, 9–10 uzman itiş eşiğindedir; 2–3 kasa, tahta/engel yoğunluğu ve statik köşe çıkmazı elemesi kullanılır. Özel gölgeli emaye depo/kasa çizimi; 48 dp D-pad, kaydırma ve komşu hücre kontrolü; geri al, ipucu, sıfırla; ayrı ilerleme anahtarı, strateji ses profili ve ortak bölüm sonucu korunur. 20-seviye benzersizlik/çözüm, telefon rota tamamlama ve telefon/tablet açılış testleri geçti; eski seviye verisi yerel kayıtta korunur. Düzeltme sonrası hedefli koşu **25**, tam proje regresyonu **271 testle** hatasız tamamlandı.
- Tamamlandı: S10 **Ağırlık Dengesi**. 300 sabit tohumlu ve birbirinden farklı vaka; her vakanın tek çözümü üretici tarafından çözücüyle kanıtlanır. Her bölümde 3–7 hassas terazi, 6–14 farklı kütleli pirinç/porselen/taş ağırlık ve aşamaya göre azalan ortak defter ipuçları kullanılır. On aşamalı ilerleme 7–8 ileri, 9–10 uzman seviyelerine çıkar. Açık emaye atölye kartı, özel çizilmiş denge terazisi, malzeme ayrımlı ağırlık tepsisi, seç–kefeye dokun etkileşimi, geri al/ipuçları/sıfırla, 48 dp hedefler ve ortak mantık sesi/bölüm kutlaması eklendi. 300 vaka çözücü testi; 320×600 Türkçe bitirme, yarım yerleşimde ipucu güvenliği ve 800×1280 İngilizce harita testleri geçti. Son tam proje koşusu: 234 test başarılı.
- Zorunlu oyun kabul kapısı: en az üç etkileşen kural/karar sistemi, kademeli zorluk, oyuna özgü kaliteli görsel kimlik, en az 48 dp dokunma alanı ve ilk 300 ardışık oynanışta aynı tahta/içerik düzeninin tekrarlanmaması. “Sonraki vaka” yeni ve daha önce sunulmamış bir düzen üretir; tekrar oynama yalnızca oyuncu tamamlanmış bir vakayı arşivden özellikle seçerse mümkündür.
- Tüm oyunlar için bölüm standardı: ilk 300 benzersiz bölüm 30 adet 10'lu pakete ayrılır. Her pakette 1–6 kademeli ustalaşma, 7–8 ileri zorluk, 9–10 uzman seviyesi olur; kampanyanın ana zorluk bantları yalnızca yükselir. Yalnızca bölüm sayısını onla doldurmak kabul edilmez: testler her paketin yerel zorluk eğrisini, çözülebilirliğini ve tekrar etmeyen içeriğini doğrular.
- Koruma notu: Mevcut 11 oyunun oyun tahtası kuralları, kayıt anahtarları, sesleri ve bölüm sonu tebrik akışı değiştirilmedi.
- S09 **Işın Yönlendir** kalite kapısı nedeniyle beklemede kalır; çoklu ışık/filtre/hedef kuralları tek çözümlü, yeterli derinlikte 300 vaka üretemezse kataloğa eklenmez. S10 **Ağırlık Dengesi** tamamlandı; sıradaki sprint seçiminde aynı kalite kapısı korunur.

## 96 adımlık kesintisiz yürütme dizisi

Her adım; kod incelemesi, dar ekran kontrolü, temel etkileşim testi ve ilgili değişikliklerin biçimlendirilmesini kapsar. Her yeni oyun, aşağıdaki **Her oyun için değişmez teslim kapısı** bölümünü geçmeden sonraki adıma geçmez.

### Aşama 1 — ortak stüdyo temeli (01–12)

| Adım | Teslim |
|---|---|
| 01 | Plan, sahiplik sınırları, mevcut oyun envanteri ve geri dönüş noktalarını sabitle. |
| 02 | Açık zeminli Studio Visuals tokenları; renk, gölge, yarıçap ve boşluk ölçeğini tek kaynağa topla. |
| 03 | `GameDefinition` sözleşmesini katalog verisi ve sınıf etiketleri için oluştur. |
| 04 | `GameSession` akışını; duraklatma, ipucu, sonuç ve skor olayları için ortaklaştır. |
| 05 | `ResponsiveGameFrame` ile telefon/tablet güvenli alan, üst bilgi ve alt eylem ölçülerini standardize et. |
| 06 | `InputPolicy` ile 48 dp hedef, sürükleme eşiği, çoklu dokunma ve yanlış dokunma korumasını uygula. |
| 07 | `StudioGameSkin` ile sekiz sınıfın vurgu rengi ve tahta materyal kurallarını uygula. |
| 08 | `GameAudioProfile` olay isimleri, ses tekrar sınırı ve haptik yoğunluğunu standardize et. |
| 09 | `ResultContract` ile yıldız, tebrik, tekrar ve katalog/daily/Arena dönüşlerini birleştir. |
| 10 | Seed, çözüm doğrulama ve zorluk parametrelerini yeni oyunlar için hazırla. |
| 11 | TR/EN metin, yazı ölçeği, renk körlüğü ve hareket azaltma kontrollerini ortak katmana ekle. |
| 12 | Telefon/tablet görünüm matrisi, analiz ve temel widget test altyapısını çalıştır. |

### Aşama 2 — mevcut 11 oyunun korunarak stüdyo görünümüne alınması (13–23)

| Adım | Mevcut oyun için teslim |
|---|---|
| 13 | Mantık Labirenti: indigo rota görünümü, sürükleme hassasiyeti ve mevcut ilerleme kaydını koru. |
| 14 | Sayı Ustası: teal sayı taşları, uzun işlem metinleri ve ipucu akışını iyileştir. |
| 15 | Sayı Peteği: altıgen taş kontrastı, iki haneli metin sığması ve geri alma kontrolü. |
| 16 | Blok Atölyesi: bırakma önizlemesi, blok gölgeleri, satır temizleme ve mevcut ses zinciri. |
| 17 | Görsel IQ: sade soru kartları, seçenek taşması ve soru geçişlerinin temizlenmesi. |
| 18 | Şekil Birleştir: parça yakalama payı, manyetik oturma ve hedef kontrastı. |
| 19 | Hafıza Labirenti: odak halkası, rota görünürlüğü ve seri geri bildirim dengesi. |
| 20 | Hanoi Kulesi: disk dokunma alanı, taşıma animasyonu ve çözücü/ipucu korunumu. |
| 21 | Şeker Sıralama: tüp derinliği, küre ayrışması, geri alma ve ipucu kontrolü. |
| 22 | Kelime Avı: Türkçe karakter, iki tahta, kaydırma sınırı ve sonuç akışı. |
| 23 | Refleks Avı: hedef güvenli bölgesi, haptik sınırı, süre okunurluğu ve tuzak ayrışması. |

### Aşama 3 — 69 yeni oyun, bir oyun = bir teslim adımı (24–92)

| Adım | Oyun | Ana teslim |
|---|---|---|
| 24 | Akış Bağlantısı | Kesişmeyen yol üreticisi, hücre mıknatıslanması ve bağlantı ses profili. |
| 25 | Devre Tamiri | Döndürülebilir parça, doğrulanabilir enerji rotası ve ivory devre görünümü. |
| 26 | Işın Yönlendir | Ayna kuralları, hamle sayısı ve taşmayan ışın efekti. |
| 27 | Köprü Kur | Ada kısıtları, çift bağ kontrolü ve açıklayıcı hata göstergesi. |
| 28 | Kapı Dizisi | Kural kartı, sabit çözüm ve sakin başarısızlık dönüşü. |
| 29 | Park Yeri | Ray-kısıtlı araç planlaması, çözücüyle doğrulanan 300 farklı tahta ve her 10'lu pakette giderek sertleşen 7–10 uzmanlık bölümleri. |
| 30 | Kilit Aç | Kaydırmalı pim kısıtları, satır sinyalleri ve erişilebilir ikonlar. |
| 31 | Dedektif Notları | İpucu matrisi, tekil çözüm doğrulaması ve kart seçimi. |
| 32 | Ağırlık Dengesi | Terazi fiziği, geniş bırakma alanı ve ibre geri bildirimi. |
| 33 | Hedef 24 | Dört kart işlem motoru, çözüm denetimi ve işlem tonları. |
| 34 | Mini Sudoku 6×6 | Üretici, nota modu, çakışma geri bildirimi ve dar ekran ızgarası. |
| 35 | KenKen Küpü | Bölge hedefi, işlem kısıtları ve çözülebilirlik testi. |
| 36 | Toplam Zinciri | Geri alınabilir zincir sürüklemesi ve hedef doğrulaması. |
| 37 | Asal Avı | Asal doğrulama, hız eğrisi ve iki yanlış sonrası dengeli tempo. |
| 38 | Kesir Fabrikası | Görsel pay/payda modeli ve dokunsal parça birleştirme. |
| 39 | Saat Ustası | Ayrık ibre hit alanları, zaman farkı ölçümü ve saat sesi. |
| 40 | Gölge Eşleştir | Tutarlı ışık yönü, çift kart seçimi ve erişilebilir silüetler. |
| 41 | Perspektif Küpü | Durdurulabilir dönüş, görünüm soruları ve hafif sürtünme sesi. |
| 42 | Parça Parkı | Serbest yerleştirme, parça sınırı ve okunur hedef silüeti. |
| 43 | Simetri Aynası | Dokunma/fırça seçeneği, ayna doğrulama ve iki tonlu zemin. |
| 44 | Mahjong Katmanları | Serbest taş çiftleriyle katmanları açma, hamle sırası ve çözülebilirlik doğrulaması. |
| 45 | Dönüş Ustası | 90° kontrolleri, yön öğretimi ve erken seviye koruması. |
| 46 | Renk Rotası | Çift kodlu renk/desen kuralı ve renk körlüğü desteği. |
| 47 | Mozaik Planı | 32 dp hücre tabanı, referans eşleştirme ve seramik taşlar. |
| 48 | Hacim Kıyasla | Perspektif hilesiz ölçü modeli ve bilimsel oyuncak görünümü. |
| 49 | Işık Dizisi | Sıra belleği, ses kapatma seçeneği ve cam düğme paketi. |
| 50 | Kart Çifti | Oyuncu kontrollü kart açma, eşleşme verisi ve çevirme sesi. |
| 51 | Odak Filtresi | Güvenli hedef doğumu, dikkat dağıtıcı üretici ve odak halkası. |
| 52 | Değişeni Bul | Sabit seed fark üreticisi, perde geçişi ve çoklu seçim. |
| 53 | Ritim Hafızası | Düşük gecikmeli pedler, metronom ve işitsel ipucu tercihi. |
| 54 | Sembol Akışı | N-adım kuralı, hareket azaltma modu ve çalışma belleği puanı. |
| 55 | Sessiz Sayım | Nesne gösterimi, sayısal seçim ve kontrastlı ayrıştırma. |
| 56 | Dikkat Tüneli | Sabit hedef alanı, çevresel tuzak kuralı ve yumuşak bulanıklık. |
| 57 | İkili Görev | Renk/yön çift kuralı, sabit kural kartları ve çift kodlu ses. |
| 58 | Su Kanalları | Döndürülebilir kanal üreticisi, iptal edilebilir çözüm animasyonu. |
| 59 | İz Takip | Kısa hafıza gösterimi, rota dışı hata modeli ve geri sürükleme. |
| 60 | Kaynak Rotası | Enerji maliyeti, düğüm ağı ve hamle önizlemesi. |
| 61 | Bahçe Sırası | Yerleştirme kısıtları, mantık doğrulaması ve mat bitki seti. |
| 62 | Kargo Düzeni | Kutu sığdırma, sınırsız geri alma ve minimum hamle yıldızları. |
| 63 | Mini Satranç Taktikleri | Küçük konum bankası, öğretici kural parçaları ve beklemesiz rakip. |
| 64 | Ada Atlama | Hamle önizlemesi, bağlantı kuralı ve görünür geri alma. |
| 65 | Zaman Çizelgesi | 48 dp satırlı planlayıcı, önkoşul denetimi ve çakışma açıklaması. |
| 66 | Anlam Eşleştir | Yaşa göre kelime havuzu, anlam kartları ve isteğe bağlı ses. |
| 67 | Atasözü Tamamla | Seçenek motoru, kısa kültürel açıklama ve iki satır metin limiti. |
| 68 | Kelime Çarkı | Çark harflerinden çapraz kelime ağı kurma; iki dilde 20 benzersiz seviye. |
| 69 | Cümle Kur | Görünür slotlar, yatay kaydırmasız uzun cümle düzeni. |
| 70 | Yakın Anlam | Anlam nüansı havuzu, bağlam açıklaması ve zorluk eğrisi. |
| 71 | Harf Labirenti | Geri alınabilir rota, kelime bankası ve mürekkep yolu. |
| 72 | Dil Dedektifi | Satır hit alanı, imla kuralı ve üst üste binmeyen açıklama. |
| 73 | Hikâye Sırası | Kabul edilen sıra kuralı, olay kartları ve sayfa kapanış sesi. |
| 74 | Renk Freni | Dürtü kontrolü kuralı, doku etiketleri ve yumuşak hata yanıtı. |
| 75 | Hedef Yağmuru | Güvenli hedef doğumu, tempo eğrisi ve ses yoğunluk sınırı. |
| 76 | Yön Değiştir | Kaydırma eşiği, erken sürükleme engeli ve yön geri bildirimi. |
| 77 | Sessiz Alarm | Hedef/boş tur dengesi, ikon ayrımı ve sessizlik tasarımı. |
| 78 | Çift Dokunuş | Hedefler arası mesafe, iki vuruş akışı ve yavaşlatmalı hata. |
| 79 | Zaman Kapısı | Zaman penceresi, azaltılmış hareket geri sayımı ve tik sesi. |
| 80 | Rota Sprinti | Swipe dizisi, sabit hata sonrası rota ve rekabet skoru. |
| 81 | Blok Akışı | 8×8 yerleştirme, özgün hedefler, sürükleme hayaleti ve combo sesi. |
| 82 | Balon Patlat | Grup sayısı, zincir doğrulama, desen kodu ve düşük keskinlikli pop. |
| 83 | Şişe Hedefi | Deterministik güç/açı fiziği ve güvenli devrilme sesi. |
| 84 | Renk Eşleştir | Renk/desen eşleşmesi, tek elle kontrol ve oyuncak kart paketi. |
| 85 | Top Birleştir | Atış hattı, adil çarpışma fiziği ve perde kontrollü ses. |
| 86 | Kule Denge | Manyetik bırakma, denge geri bildirimi ve kırılmasız başarısızlık. |
| 87 | Mıknatıs Yolu | Görünür etki yarıçapı, toplama fiziği ve çekim sesi. |
| 88 | Mini Golf Rota | Güç eğrisi, bir/iki vuruş hedefleri ve görünür top gölgesi. |
| 89 | Kaydırmalı Tatlı | Kaydırmalı mantık matrisi, hedef deseni ve özgün jelatin varlıklar. |
| 90 | Halka At | Güç/açı modeli, rastlantısız hedefleme ve rezonans sesi. |
| 91 | Küçük Balıkçı | Zamanlama penceresi, istenmeyen nesne kuralı ve sakin yüzey. |
| 92 | Mermer Rota | Yön pedleri, isteğe bağlı eğim simülasyonu ve hız ölçekli yuvarlanma. |

### Aşama 4 — yayın adayı (93–96)

| Adım | Teslim |
|---|---|
| 93 | 80 oyunun tamamında teslim kapısı, seviye seed testi ve kayıt geçişi denetimi. |
| 94 | FPS, bellek, ses yoğunluğu, düşük donanım ve çevrimdışı çalışma profili. |
| 95 | Feature flag, günlük görev/Arena havuzu, TR/EN içerik ve kapalı test sürümü. |
| 96 | Sürüm notu, imzalı APK/AAB, mağaza görselleri ve kademeli yayın kontrol listesi. |


## Ürün ilkesi

- Oyuncu deneyimi: kısa oturum, ilk dokunuşta anlaşılır hedef, ustalaşınca derinleşen kural seti.
- Katalog deneyimi: açık zemin, sakin beyaz yüzey, `teal` ana eylem, `amber` ödül, kategoriye özgü tek vurgulu renk.
- Oyun deneyimi: oyun tahtası için işlevsel kontrast korunur; menü yüzeyleriyle aynı renk dili sürer. Beyaz katalog dili nedeniyle bir oyun tahtasının okunurluğu düşürülmez.
- Özgünlük: Block Blast, match-3, sort ve bubble-pop gibi tanıdık türlerin **mekanik ilkeleri** incelenir; ad, görsel, ses, seviye düzeni, metin, ikon, ekonomi ve marka unsuru kopyalanmaz.
- Kapsam: her oyunun tek bir ana beceri vaadi vardır. Aynı kontrol biçimini kullansa dahi hedef, hata modeli, tempo ve ödül ritmi başka oyundan ayrışır.

## 0. Ortak üretim sprinti — oyun eklemeden önce zorunlu temel

Bu sprint, 80 oyunun her birinden önce tamamlanır ve sonraki tüm sprintlerin giriş koşuludur.

1. `GameDefinition`: kimlik, sınıf, kısa/uzun başlık, zorluk eğrisi, günlük görev uygunluğu, Arena uygunluğu, erişilebilirlik ve ses profili için tek veri sözleşmesi.
2. `GameSession`: sayaç, duraklatma, ipucu, yeniden başlatma, sonuç, yıldız ve skor olaylarını ortaklaştırır. Oyun mantığı bu sınıfa taşınmaz; yalnızca akış tekrarı taşınır.
3. `ResponsiveGameFrame`: 320×600, 360×640, 393×852, 412×915, 768×1024 ve geniş tablet için güvenli alan, üst bilgi ve alt eylem yüksekliği sağlar.
4. `InputPolicy`: hedef alan minimum 48 dp; sürüklemede en az 8 dp hareket eşiği; sürükleme sırasında tek aktif parmak; yanlışlıkla arka plan tıklamasını yutan katman; hızlı çift dokunuşta kilitlenmeyen durum makinesi.
5. `StudioGameSkin`: her sınıf için bir vurgu rengi, `ivory` yüzey, koyu mürekkep metin ve yüzde 8–14 aralığında yumuşak vurgu yüzeyi. Doygun gradyan, neon parıltı ve rastgele gölge yasaktır.
6. `GameAudioProfile`: UI tıklaması, hazırlık, doğru, yanlış, özel hamle, süre uyarısı ve sonuç için anlamlı olay isimleri. Var olan `GameAudioService`, ses/haptik tercihleri ve bölüm sonu tebrik zinciri korunur.
7. `ResultContract`: başarıda aynı yıldız/rekor/sonraki bölüm/tekrar akışı; günlük parkur, Arena ve normal oyun dönüşlerinde aynı `ParkurGameResult` sözleşmesi.
8. `ContentSeed`: seviye üreticisi için seed, doğrulanabilir çözüm, hedef zorluk ve tekrar oynama parametresi. Rastgelelik asla çözümsüz veya haksız seviye üretmez.

## Her oyun için değişmez teslim kapısı

Her aşağıdaki sprint, “bitti” sayılmadan önce bu 13 kapının tamamını geçer:

1. 320 dp genişlikte yatay taşma, `RenderFlex overflow` ve kesilen CTA yok.
2. Türkçe ve İngilizce uzun metinler iki satır sınırı veya ölçülü küçülme ile görünür; kritik metin sadece ikonla bırakılmaz.
3. Sistem yazı ölçeği %80, %100, %115 ve %150’de amaç, skor, süre ve geri düğmesi erişilebilir kalır.
4. Telefon çentiği, alt hareket çubuğu, klavye ve yatay dönüşte etkin alan güvenlidir.
5. Tek elle kullanım: ana hedefe erişim 48 dp, sürüklemede parmak altında net gölge/önizleme, dokunma geri bildirimi 100 ms içinde.
6. Hata durumu net: yanlış hamle renk tek başına değil, hareket ve kısa metinle de anlatılır.
7. İlk üç bölümde yeni kural bir kez, eylem üstünde gösterilir; uzun öğretici ekran yoktur.
8. Seviye üretici en az 1.000 seed ile çözülebilirlik, hedef süre ve hata toleransı testinden geçer.
9. Her oyunun 300 benzersiz bölümü 10'lu paketlere ayrılır: 1–6 kademeli öğrenme/ustalaşma, 7–8 ileri, 9–10 uzman; kampanya bantları geriye gitmez. Bölüm testleri bu yerel ve kampanya eğrisini ayrı ayrı denetler.
10. Sesler telifsiz/özgün, kısa, kesintisiz ve oyun türüne uygun; aynı ses 40 ms içinde tekrar tetiklenmez. Var olan tebrik ve yıldız sistemi devam eder.
11. 60 fps hedefi: oyun sırasında disk okuması, büyük görsel çözme ve bloklayıcı ağ çağrısı yok; varlıklar girişte önceden hazırlanır.
12. Widget testi: TR dar telefon + EN tablet açılışı, bir ana hamle, ipucu, başarısızlık, başarı ve sonuç geri dönüşü.
13. İnsan QA: iki başparmak, tek başparmak, hızlı sürükleme, yanlış dokunuş, ekran döndürme ve arka plana alma senaryoları elle oynanır.

## Görsel sınıflar ve renk imzaları

| Sınıf | Ana görsel dili | Vurgu | Tahta materyali |
|---|---|---|---|
| Mantık ve problem çözme | yön, düğüm, yol | indigo `#6F63C8` | mat seramik + ince çizgi |
| Sayılar ve hesaplama | sayı taşı, kadran, ızgara | teal `#259C89` | ivory taş + teal gravür |
| Görsel ve uzamsal | blok, gölge, perspektif | rose `#C76E93` | yumuşak polimer + hafif derinlik |
| Hafıza ve dikkat | ritim, odak halkası, iz | amber `#D89A42` | sisli cam + sıcak ışık |
| Planlama ve strateji | rota, katman, kaynak | terracotta `#D07F52` | ahşap/seramik hibrit |
| Dil ve kelime | kart, harf, mürekkep | mavi `#5B88C8` | kâğıt + baskı dokusu |
| Hız ve tepki | net hedef, darbe, tempo | coral `#D96767` | kauçuk + emaye |
| Eğlence oyunları | dokunsal oyuncak, tatmin | teal + amber | oyuncak seramik, asla neon değil |

Her yeni görsel, kategoriye ait 3B render ailesinden gelir: gerçekçi olmayan ama fiziksel olarak tutarlı malzeme; yumuşak stüdyo ışığı; metinsiz; şeffaf arka plan; tek odak nesnesi. AI üretimi kullanılırsa yüz, el, yazı, logo, karmaşık arka plan ve birbiriyle tutarsız perspektif kabul edilmez. Kullanımdan önce alfa kanalı, kenar halo, 1×/2×/3× çözünürlük ve koyu/açık yüzey üzerinde kontrast kontrol edilir.

## Sprint sıralaması — 80 oyun

Tablodaki “kontrol” alanı, oyunun özgün çekirdeğini ve hata önleme kuralını; “görsel/ses” alanı ise o oyuna özgü teslimi belirtir. Yukarıdaki teslim kapısı her satıra ek olarak zorunludur.

### A. Mantık ve problem çözme — 10 oyun

| Sprint | Oyun | Durum | Çekirdek döngü ve kontrol | Görsel/ses teslimi |
|---|---|---|---|---|
| S01 | Mantık Labirenti | Mevcut | Hedefe rota çizme; sürükleme yolu hücre merkezine mıknatıslanır, geri dönüşte tek adım silinir. | Indigo yol taşları; adım, duvar, ipucu ve hedef sesleri mevcut profil üzerinden dengelenir. |
| S02 | Akış Bağlantısı | Yeni | Aynı renkteki iki terminali yollar kesişmeden bağlama; parmak kalkınca geçersiz yol geri alınır. | İnce kablo kanalları, bağlantı “klik”i, tamamlanan devrede kısa harmonik. |
| S03 | Devre Tamiri | Yeni | Döndürülebilir parça ile enerji kaynağını çıkışa ulaştırma; dokunma 90° döndürür. | Ivory devre kartı, teal akım parçacığı, düşük frekanslı enerji açılma sesi. |
| S04 | Dedektif Notları | Tamamlandı | Kişi, eser, oda ve sıra ilişkilerini en az 3 etkileşen çıkarım sistemiyle çözme; 300 düzen ve tüm çözümler testlerle doğrulanır. | Editoryal dedektif dosyası: kırık beyaz kâğıt, mürekkep laciverti, ölçülü pirinç detaylar; kontrollü kanıt/kalem sesleri. |
| S05 | Köprü Kur | Tamamlandı | Her adanın derece sayısını tamamla; aynı rota en fazla iki köprü alır, köprüler kesişmez ve bütün ağ bağlı kalır. Her vakada tek çözüm doğrulanır. | Kırık beyaz mühendislik planı, seramik adalar, grafit/oksit köprüler ve katmanlı özel Canvas çizimi; ince ızgara ve yumuşak stüdyo gölgesi. |
| S06 | Kapı Dizisi | Tamamlandı | Konum, önce/sonra, komşuluk, mesafe, arada olma ve tek/çift sıra ipuçlarını birleştir; 5–8 kapı ile dört zorluk bandında 300 deterministik, benzersiz ve tek çözümlü vaka. Konum seçerek yerleştirme, taş takası, geri al, boşaltma, ipucu ve sıfırlama. | Kırık beyaz arşiv paneli, mürekkep metni, ölçülü bakır/indigo vurgular ve özel Canvas kasa çizimi. Türkçe/İngilizce, küçük telefon ve tablet düzeni; mevcut mantık ses profili ve ortak sonuç/tebrik akışı. |
| S45 | Mayın Dedektifi | Tamamlandı — Best 20 S03 | 20 deterministik ve tekrarsız alan; 3×3 güvenli açılış ve doğrudan/alt-küme çıkarımlarıyla tahminsiz çözülebilirlik sertifikası. İşaret, hücre açma, sıfır alanı, geri al ve ipucu; her 10'lu bölümde 7–8 ileri, 9–10 uzman zorluğu. | Açık seramik araştırma tahtası; logic sınıfı ses, erişilebilir hücre etiketleri ve ortak sonuç kutlaması. 320×600 Türkçe çözüm ve 800×1280 İngilizce merkez doğrulandı. |
| S08 | Kilit Aç | Tamamlandı | Beş–sekiz pim, dört çentik seviyesi; yıldız bağlantı toplamları ve üçgen denge bağı pim değerlerini tekil çözer. Her 10'lu pakette ek destek ipucu bütçesi 9'dan 0'a düşer; 7–8 ileri, 9–10 uzman. 300 deterministik, tekrar etmeyen ve çözücüyle doğrulanan kilit; satır sinyali, ipucu, geri alma, sıfırlama ve ortak ilerleme sözleşmesi. | Açık kırık beyaz seramik yüzey, özel Canvas kilit rozeti, sakin emaye/teal ve pirinç vurgular; açıklayıcı sinyal ikonları, 48 dp seçenekler, mantık sınıfı ses ve ortak bölüm sonu kutlaması. Türkçe kompakt telefon/İngilizce tablet testleri geçti. |
| S09 | Işın Yönlendir | Beklemede | Tek ayna/tek ışın döngüsü yeterli derinlik sağlamıyor; çoklu ışık kaynakları, renk filtreleri ve etkileşen hedef koşulları tasarlanmadan kataloğa alınmaz. | Optik kurallar ve çoklu hedefler netleşince özgün malzeme/ışık dili tanımlanacak. |
| S10 | Ağırlık Dengesi | Tamamlandı | 300 deterministik, tekrarsız ve tek çözümlü vaka; 3–7 terazi, her parçada tekil kütle, aynı/farklı malzeme kısıtları ve kademeli ortak ipuçları. On aşamada 7–8 ileri, 9–10 uzman. Seç–kefeye dokun, ipucu, geri al, sıfırla; ortak ilerleme/puan/yıldız anahtarları. | Kırık beyaz emaye atölye yüzeyi, özel Canvas terazi rozeti, pirinç/porselen/taş ağırlık dili, 48 dp kefeler, sade hiyerarşi; mantık sınıfı ses ve ortak bölüm kutlaması. 300-vaka çözücü, kompakt/tablet açılışı ve kısmi yerleşim güvenliği doğrulandı; tam proje paketi 234 test geçti. |

### B. Sayılar ve hesaplama — 9 oyun

| Sprint | Oyun | Durum | Çekirdek döngü ve kontrol | Görsel/ses teslimi |
|---|---|---|---|---|
| S11 | Sayı Ustası | Mevcut | Sayı hedefini işlemlerle çözme; işlem sırası ve ipucu mantığı korunur. | Teal sayı taşları, doğru/yanlış/seri sesleri seviye temposuna göre ayrılır. |
| S12 | Sayı Peteği | Mevcut | Hücrelere doğru sıralı değerleri yerleştirme; geri alma ve ipucu korunur. | Altıgen taşlarda gölge yönü sabit, küçük metin için iki haneli kısaltma kuralı. |
| S13 | Hedef 24 | Tamamlandı | Her elde farklı dört sayı kartını, seçilen işlemi ve sıralı iki kart dokunuşunu kullanarak tek işlem ağacında 24'e ulaştır. Tam kesirli ara sonuçlar desteklenir; bölme-sıfır engellenir; geri al, ipucu, sıfırla ve son kontrol vardır. 300 deterministik el, kart kümeleri ve çözücüyle tek çözüm doğrulandı. Her 10'lu pakette zorluk yükselir; 7–8 ileri, 9–10 uzman. | Açık seramik masa, grafit tipografi, sakin teal ve pirinç vurgular, özel hedef halkası ve sayı kartı tahtası; 48 dp+ dokunma hedefleri, dar ekran kaydırma ve uzun etiket taşma güvenliği. Sayı sınıfı ses profili, mevcut bölüm kutlaması ve ortak ilerleme/yıldız/puan kaydı. 320×600 kompakt telefonda tam çözüm, 800×1280 İngilizce merkez ve proje genelinde 239 test geçti. |
| S14 | Mini Sudoku 6×6 | Tamamlandı | Sayı Ustası’ndaki Sudoku soru ailesinden bağımsız, kendi parkuru ve ilerleme anahtarı olan 6×6 oyun. Her satır/sütun 1–6’yı bir kez, her 2×3 bölge altı sembolü birer kez içerir. 300 deterministik, birbirinden farklı tahta tek çözümle doğrulandı. Her aşamada verilen ipucu azalır: 1’de 28 hücreden 10’da 14’e; 7–8 ileri, 9–10 uzman (19–22 boş hücre). Ayrı not modu; hücre seçimi, sayı tuş takımı, geri al, temizle, ipucu ve sıfırla. | Sütlü beyaz/ivory tahta, grafit sayılar, düşük doygunluklu teal seçim/aynı birim vurgusu, çakışmada ölçülü coral; 2×3 bölgeler özel ızgara çizgisiyle belirgin. En az 48 dp sayı ve işlem hedefleri, küçük ekranda kontrollü dikey kaydırma, sabit ipuçlarını düzenlemeye karşı koruma. Sayı sınıfı ses profili ve mevcut bölüm sonu kutlaması. 320×600’de tam çözüm, not/geri al akışı ve 800×1280 İngilizce merkez testi; tam proje test paketi 245 test geçti. |
| S15 | KenKen Küpü | Tamamlandı — Best 20 S01 | Sayı Ustası’ndaki aritmetik soru ailesinden ayrı, kendi parkuru ve ilerleme anahtarı olan kafes/Latin tablo oyunu. Aşama boyutu 4×4’ten 6×6’ya çıkar; kafesler toplama, çarpma, çıkarma ve tam bölme kullanır. 20 deterministik, birbirinden farklı tahta çözücüyle tek çözümlü doğrulanır; her onlu bölümde 7–8 ileri, 9–10 uzman. Hücre seçimi, tuş takımı, geri al, sil, ipucu ve sıfırlama. | Ivory seramik tahta, grafit rakam, ince kafes sınırları ve ölçülü amber hedef etiketi; 48 dp sayı/araç hedefleri, 320×600 küçük ekranda kontrollü kaydırma ve taşma testi, İngilizce tablet hub testi. Sayı sınıfı ses profili ve mevcut bölüm sonu kutlaması; puan/yıldız/ilerleme bağımsız kaydedilir. 20 içerik benzersizlik/tek çözüm, aşama zorluğu ve tamamlama akışı doğrulandı. |
| S16 | Gizli Kütleler | Tamamlandı | Dengeli tartım toplamlarından bilinmeyen nesne kütlesini çıkarma; 20 farklı ve tek çözümlü tahta, ikinci pakette çeldirici nesne, 7–10 ve 17–20 uzman zinciri. | Açık seramik yüzey, sakin mor mantık sınıfı, ortak ses/tebrik düzeni. Telefon/tablet yerleşimi ve tekil çözüm regresyonları doğrulandı. |
| S17 | Asal Avı | Yeni | Sayı yağmurunda yalnız asal sayıları seçme; tempo kademeli artar, iki yanlışta kısa yavaşlama uygulanır. | Mavi sayı pulları, hedef darbesi, yanlışta kırmızı flaş yerine titreşim. |
| S18 | Kesir Fabrikası | Yeni | Parçaları birleştirerek gösterilen kesri üretme; görsel pay/payda oranı metinden önce anlatır. | Ivory ölçü kapları, sıvı değil soyut renk blokları, doğru eşleşmede tok ses. |
| S19 | Saat Ustası | Yeni | Analog saati hedef saate döndürme ve süre farkını okuma; ibreler ayrı dokunma alanına sahiptir. | Mat saat kadranı, tik-tak aşırı tekrarlanmaz, doğru saat zili çok kısa. |

### C. Görsel ve uzamsal düşünme — 12 oyun

| Sprint | Oyun | Durum | Çekirdek döngü ve kontrol | Görsel/ses teslimi |
|---|---|---|---|---|
| S20 | Blok Atölyesi | Mevcut | Blokları ızgaraya yerleştirme ve satır/sütun temizleme; sürükleme önizlemesi ve hassas bırakma korunur. | 3B blok kenarları sadeleştirilir; pickup/place/clear/mega ses zinciri korunur. |
| S21 | Görsel IQ | Mevcut | Şekil kuralı, eksik parça ve dizi çözümü; soru havuzu ve tekrar akışı korunur. | Rose kategori yüzeyi, soru kartlarında tek odak, dekoratif gürültü yok. |
| S22 | Şekil Birleştir | Mevcut | Parçayı hedef silüete yerleştirme; sürükleme yakalama alanı parça sınırından %12 geniş olur. | Yumuşak polimer parçalar, doğru oturmada manyetik “snap” sesi. |
| S23 | Gölge Eşleştir | Yeni | Nesneyi doğru gölgesiyle eşleştirme; seçim çift kart üzerinden, sürükleme gerekmez. | Tek ışık yönü, belirsiz silüet yok, eşleşmede yumuşak çan. |
| S24 | Perspektif Küpü | Yeni | Dönen küpün üst/ön/yan görünümünü seçme; animasyon durdurulabilir. | Ivory–teal küp, 12 fps üzeri sorunsuz dönüş, döndürme sesi değil hafif sürtünme. |
| S25 | Parça Parkı | Yeni | Tetris-benzeri parçaları hedef alanı doldurmak için serbestçe yerleştirme; verilen parça sayısı sınırlıdır. | Bahçe değil soyut masa üstü, parça oturunca hafif gölge derinleşmesi. |
| S26 | Simetri Aynası | Yeni | Yarımı verilen deseni diğer yana aynalama; hücre dokunması ve fırça sürüklemesi seçenekli. | Cam ayna çizgisi, doku yerine sade iki ton, tam simetride parıltısız başarı halkası. |
| S27 | Mahjong Katmanları | Tamamlandı — Best 20 S02 | Klasik Mahjong'un serbest taş kuralıyla üstü açık ve bir kenarı açık çiftleri eşleştir; katman açılımını ve eş seçme sırasını planla. 20 deterministik ve farklı tahtada çözüm rotası gerçek kuralla tekrar oynatılarak doğrulanır; her onlu bölümde 7–8 ileri, 9–10 uzman katman yoğunluğu. | Ivory seramik taşlar, grafit işaretler, ölçülü teal seçim ve amber serbest taş halkası; fiziksel ama sakin katman gölgesi, görsel sınıf ses profili, ortak sonuç kutlaması ve çözümü bozmayan görünüm çevirme. 320×600 telefon, 800×1280 tablet, katalog ve tüm oyun merkezi regresyonları geçti. 20 içerikte tekrar etmeme/çözüm testi tamamlandı. |
| S28 | Dönüş Ustası | Yeni | Şekli 90° adımlarla doğru yönde hizalama; ilk 5 seviyede serbest dönüş kapalıdır. | Köşe tutamacı yerine büyük dönüş düğmeleri, yön doğrulama sesi. |
| S29 | Renk Rotası | Yeni | Renk geçişi kuralına göre yolları seçme; renk körlüğü için desen ve ikon birlikte kullanılır. | Düşük doygun palet, renk yanında şekil göstergesi, hedefte iki kanallı geri bildirim. |
| S30 | Mozaik Planı | Yeni | Referans mozaikteki bölgelere doğru taşları koyma; yakınlaştırma yok, hücreler minimum 32 dp. | Seramik karo, tekil yerleştirme sesi, tamamlanan satırda hafif ritim. |
| S31 | Hacim Kıyasla | Yeni | Kap/nesne çiftlerinde daha büyük hacmi seçme; perspektif hilesi yerine bilgi kısıtı kullanılır. | Sütlü cam kaplar, ölçek doğrulaması bilimsel ama oyuncak hissinde. |

### D. Hafıza ve dikkat — 10 oyun

| Sprint | Oyun | Durum | Çekirdek döngü ve kontrol | Görsel/ses teslimi |
|---|---|---|---|---|
| S32 | Hafıza Labirenti | Mevcut | Görünen rotayı hatırlayıp izleme; seri, tuzak ve ipucu davranışı korunur. | Amber odak halkası, mevcut nota/dönüş sesleri daha düşük tekrar yoğunluğunda. |
| S33 | Işık Dizisi | Yeni | Yanan düğme dizisini tekrar etme; her tur yalnız bir yeni eleman eklenir. | Cam düğmeler, notalar ses motorundaki bellek notalarıyla eşlenir. |
| S34 | Kart Çifti | Yeni | Görsel çiftleri en az hamlede bulma; açık kartlar yarım saniye sonra otomatik kapanmaz, oyuncu kontrolü vardır. | Aynı 3B varlık ailesi, çevirme sesi, eşleşmede kısa yumuşak akor. |
| S35 | Odak Filtresi | Yeni | Hedef simgeyi dikkat dağıtıcılar arasında bulma; hedef asla parmak altında aniden doğmaz. | Sisli cam katman, hedefte amber halka, yanlış seçimde kısa haptik. |
| S36 | Değişeni Bul | Yeni | Kısa perde sonrası değişen 1–3 öğeyi seçme; iki ekran arasındaki fark sabit seed ile test edilir. | Kâğıt masa üstü, geçişte perde animasyonu, tespit tıkırtısı. |
| S37 | Ritim Hafızası | Yeni | Vuruş ve boşluk dizisini ritim pedlerinde tekrar etme; işitsel ipucu kapatılabilir. | Kauçuk pedler, düşük gecikmeli vurma sesleri, görsel metronom. |
| S38 | Sembol Akışı | Yeni | Akan simgelerde n-adım önceki simgeyle eşleşeni seçme; hız değil çalışma belleği ölçülür. | Mavi mürekkep simgeler, hareket azaltma ayarında akış adımlı ilerler. |
| S39 | Sessiz Sayım | Yeni | Hızla gösterilen nesne sayısını hatırlama; gösterim sonrası sayısal seçim yapılır. | Sakin ivory sahne, nesne çokluğu erişilebilir kontrastla ayrılır. |
| S40 | Dikkat Tüneli | Yeni | Ortadaki hedefe odaklanırken çevre değişimlerini yok sayma; hedef alan sabittir. | Vinyet yerine yumuşak bulanıklık, yanlış çevresel dokunuşa nötr ses. |
| S41 | İkili Görev | Yeni | Renk kuralı ve yön kuralını aynı turda izleme; kural kartları ekranın üstünde sabit kalır. | İki ayrı işaret sistemi, rengin yanına yön ikonu, iki kanallı ses. |

### E. Planlama ve strateji — 10 oyun

| Sprint | Oyun | Durum | Çekirdek döngü ve kontrol | Görsel/ses teslimi |
|---|---|---|---|---|
| S42 | Hanoi Kulesi | Mevcut | Diskleri kural ihlalsiz hedefe taşıma; geri alma, eğitim ve çözücü ipucu korunur. | Terracotta diskler, disk bırakmada mevcut güvenilir sesler korunur. |
| S43 | Şeker Sıralama | Mevcut | Renkli parçaları tüplerde sıralama; geri alma/ipucu/tekrar korunur. | Şeker yerine soyut parlak küreler; tüp derinliği gerçekçi ama okunur. |
| S44 | Su Kanalları | Yeni | Kanalları döndürüp suyu hedeflere ulaştırma; çözüm sonrası su animasyonu iptal edilebilir. | Seramik oluklar, düşük yoğunluklu su sesi, renk körlüğü için hedef sembolü. |
| S07 | Park Yeri | Tamamlandı | Ray kısıtlı 6×6 trafikte 300 benzersiz, en kısa çözümü doğrulanmış bulmaca; her 10'lu pakette 7–8 ileri, 9–10 uzman zorluğu. Sürükleme yalnız araç rayında, engel önizlemede hissedilir. | Sakin açık menüler, koyu asfalt/ince park çizgileri, numaralı mat araç gövdeleri ve ortak strateji ses/tebrik profili. |
| S46 | Kaynak Rotası | Yeni | Sınırlı enerjiyle istasyonları bağlama; her hamlede maliyet görünür. | Harita yerine masa üstü düğüm ağı, kaynak düşüşü gizlenmez. |
| S47 | Bahçe Sırası | Yeni | Büyüme kısıtlarına göre bitki taşlarını yerleştirme; estetik hedef değil mantık hedefi. | Mat yaprak ikonları, toprak dokusu abartısız, yerleştirme sesi kuru ve kısa. |
| S48 | Depo Ustası | Tamamlandı — Best 20 S04 | Yürüme ve itiş ayrı sayılır; kasalar çekilemez, köşe çıkmazı stratejik kilittir. 20 benzersiz düzende push-space BFS en az itiş çözümünü kanıtlar; her 10'lu bölümde 7–8 ileri ve 9–10 uzman hedef eşikleri bulunur. | Açık emaye depo zemini, yumuşak seramik duvarlar, malzeme dokulu gölgeli kasalar ve pirinç hedef mühürleri. 48 dp yön kontrolü, sürükleme, geri al/ipuçları/sıfırla ve ortak strateji sesi/tebrik akışı. |
| S49 | Mini Satranç Taktikleri | Yeni | 3–6 taşlı tek hamle/iki hamle taktiği; kurallar oyun içinde parça parça öğretilir. | Soyut taş seti, kareler yüksek kontrast, rakip bekleme yok. |
| S50 | Ada Atlama | Yeni | Sınırlı hamleyle bağlantı noktalarını ziyaret etme; her adım önizlemesi gösterilir. | Terracotta ada taşları, atlamada hafif tok ses, geri alma görünür. |
| S51 | Zaman Çizelgesi | Yeni | Görevleri süre ve önkoşula göre takvime yerleştirme; sürükleme çizelgesi 48 dp satır yüksekliği kullanır. | Kâğıt planlayıcı görünümü, çakışmada metinli açıklama, yumuşak kalem sesi. |

### F. Dil ve kelime — 9 oyun

| Sprint | Oyun | Durum | Çekirdek döngü ve kontrol | Görsel/ses teslimi |
|---|---|---|---|---|
| S52 | Kelime Avı | Mevcut | Harf tahtasında kelime bulma; iki tahta, locale verisi ve kaydırma sınırları korunur. | Mavi mürekkep seçimi, harf aralığı erişilebilir kalır, sonuç sesi korunur. |
| S53 | Anlam Eşleştir | Yeni | Kelimeyi doğru anlam kartına eşleme; yaş grubuna göre kelime havuzu filtrelenir. | Kâğıt kartlar, doğru bağ çizgisi, sesli okuma isteğe bağlı. |
| S54 | Atasözü Tamamla | Yeni | Eksik kelimeyi seçeneklerden seçme; kültürel açıklama sonuçta kısa görünür. | Baskı mürekkebi, iki satır sınırı, yanlışta öğretici açıklama. |
| S55 | Kelime Çarkı | Tamamlandı | Harf çarkından kelime kurup kesişen bulmacayı doldurma; TR/EN için 20 sabit ve benzersiz tahta, ikinci bölümde çeldirici harf. 7–10 ve 17–20 uzman bandında artan kelime hedefi. | Açık seramik/mavi sınıf görünümü, dokunma ve sürükleme girişi, sınıf ses profili ve ortak bölüm sonu kutlaması. 320×600 telefon, tablet, katalog ve kampanya testleri geçti. |
| S56 | Cümle Kur | Yeni | Karışık sözcük kartlarını doğru sözdizimine dizme; sürükleme slotları görünür. | Kâğıt şeritler, dize yerleşince hafif snap, uzun cümlede yatay kaydırma yok. |
| S57 | Yakın Anlam | Yeni | Hedef kelime için en yakın anlamı ayırt etme; zorlukta anlam nüansı artar. | İki tonlu kartlar, cevaptan sonra 1 cümlelik bağlam. |
| S58 | Harf Labirenti | Yeni | Komşu harflerden hedef kelime rotası çizme; rota geri alınabilir. | Mürekkep yolu, her harfte yumuşak pluck, kelime sonunda akor. |
| S59 | Dil Dedektifi | Yeni | Cümledeki yazım/noktalama hatasını işaretleme; hit alanı satır yüksekliğinin tamamı. | Editör kâğıdı, hata altı çizgisi, açıklama üst üste binmez. |
| S60 | Hikâye Sırası | Yeni | 3–6 olay kartını mantıklı sıraya koyma; birden fazla makul sıra varsa kabul mantığı tanımlanır. | Resimli kartlar, sıralama rayı, finalde kısa sayfa kapanış sesi. |

### G. Hız ve tepki — 8 oyun

| Sprint | Oyun | Durum | Çekirdek döngü ve kontrol | Görsel/ses teslimi |
|---|---|---|---|---|
| S61 | Refleks Avı | Mevcut | Hedefe dokunma, tuzaktan kaçınma ve seri; hedef şekli/tempo korunur. | Coral hedefler, mevcut hit/bomb sesleri ve haptik sınırları korunur. |
| S62 | Renk Freni | Yeni | Renk sözcüsü ile yazı renginin kuralına göre dokunma; reaksiyon değil dürtü kontrolü ölçülür. | Coral–teal çift kodu, renk körlüğünde doku etiketi, yanlışta sert ses yok. |
| S63 | Hedef Yağmuru | Yeni | Sabit boyuttaki hedefler alana düşer; hedefler alt sistem çubuğu veya çentik altında doğmaz. | Kauçuk hedefler, darbe sesi çoklu tetikleme sınırında. |
| S64 | Yön Değiştir | Yeni | Ok yönü kuralına göre sola/sağa kaydırma; erken sürükleme kabul edilmez. | Emaye oklar, eşik çizgisi, doğru swipe sesi. |
| S65 | Sessiz Alarm | Yeni | Sadece belirli ikon görülünce dokunma; bekleme turları oyuncuyu yanıltmaz. | İnce odak halkası, sessizlik anları ses eksikliği olarak tasarlanır. |
| S66 | Çift Dokunuş | Yeni | Aynı sembol çifti göründüğünde iki hedefe sırayla basma; minimum hedefler arası mesafe 56 dp. | İki parçalı vurma sesi, hatada animasyon yavaşlatma. |
| S67 | Zaman Kapısı | Yeni | Daralan zaman penceresinde göstergede doğru anda basma; animasyon azaltmada sayısal geri sayım da vardır. | Amber saat halkası, tek tik sesi, görsel titreşim olmadan uyarı. |
| S68 | Rota Sprinti | Yeni | Kısa yön dizisini mümkün olan en hızlı doğru swipe ile bitirme; yanlışta dizi yeniden karışmaz. | Coral rota şeridi, kaydırma sesleri yön kodlu, rekabet skoru ayrı kaydedilir. |

### H. Eğlence oyunları — 12 oyun

| Sprint | Oyun | Durum | Çekirdek döngü ve kontrol | Görsel/ses teslimi |
|---|---|---|---|---|
| S69 | Blok Akışı | Yeni | Üç parça arasından seçim yapıp 8×8 tahtada satır/sütun tamamlama; türün tanıdık yerleştirme ritmi özgün seviye hedefleriyle uygulanır. | Ivory–teal bloklar, sürükleme hayalet parçası, özgün pickup/place/combo ses seti. |
| S70 | Balon Patlat | Yeni | Aynı renk komşu balon grubuna dokunup zincir oluşturma; patlamadan önce grup sayısı görünür. | Yarı saydam balonlar, düşük keskinlikte pop, renk körlüğünde desen. |
| S71 | Şişe Hedefi | Yeni | Güç ve yön göstergesiyle topu hedef şişelere gönderme; fizik sabit seed ile deterministik. | Oyuncak şişeler, cam kırılma yerine güvenli tok devrilme sesi. |
| S72 | Renk Eşleştir | Yeni | Akan kartlardaki renk/desen çiftlerini hızlı eşleştirme; iki elle zorunluluğu yoktur. | Teal/amber oyuncak kartlar, eşleşme “snap”i, 3D derinlik sınırlı. |
| S73 | Top Birleştir | Yeni | Aynı numaralı topları birleştirip daha büyük değer üretme; atış hattı parmakla kısmen kapanmaz. | Amber cam toplar, çarpışma sesi perde kontrollü, fizik adil. |
| S74 | Kule Denge | Yeni | Farklı şekilleri devirmeden istifleme; bırakma noktası parça merkezine manyetik. | Mat seramik parçalar, denge haptiki, başarısızlıkta kırılma yok. |
| S75 | Mıknatıs Yolu | Yeni | Mıknatısı sürükleyip metal pulları hedefe toplama; alan etkisi yarıçap olarak görünür. | Teal manyetik halka, metalik olmayan yumuşak çekim sesi. |
| S76 | Mini Golf Rota | Yeni | Bir veya iki vuruşta topu deliğe sokma; sürükleme güç eğrisi öğreticide açıklanır. | Ivory masa üstü saha, vuruş sesi, topun kaybolmayan gölgesi. |
| S77 | Kaydırmalı Tatlı | Yeni | Sıralı kutuları kaydırıp hedef deseni kurma; match-3 kopyası değil, kaydırmalı mantık yapısı. | Soyut tatlı renkleri yerine jelatin şekiller, swap sesi, hedef matrisi. |
| S78 | Halka At | Yeni | Güç/açıyla halkayı pime geçirme; rüzgâr gibi gizli rastlantı kullanılmaz. | Kauçuk halka, seramik pim, halka oturduğunda kısa rezonans. |
| S79 | Küçük Balıkçı | Yeni | Zamanlamayla tek hedefi yakalama, istenmeyen nesneden kaçınma; çocukça değil sakin masa üstü minigame. | Kâğıt-su yüzeyi, bobber sesi, etik av yerine soyut koleksiyon objesi. |
| S80 | Mermer Rota | Yeni | Tahtayı değil, yön pedlerini kullanarak mermeri hedefe götürme; eğim simülasyonu isteme bağlıdır. | Amber mermer, teal kanallar, yuvarlanma sesi hızla ölçeklenir, durduğunda kesilir. |

## Dalga planı ve bağımlılıklar

1. **Dalga 1 — koruma ve temel:** S01, S11, S20, S32, S42, S52, S61. Yedi ana sınıfın mevcut bir temsilcisi ortak çerçeveye alınır; skor, günlük görev ve Arena dönüşleri değişmeden kalır.
2. **Dalga 2 — sınıf derinliği:** S02–S10, S12–S19, S21–S31. Seviye üreticileri, veri sözleşmesi ve sınıf başına görsel varlık paketi tamamlanır.
3. **Dalga 3 — bilişsel çeşitlilik:** S33–S60. Aynı tutma hareketi veya aynı soru tipi art arda iki oyunda kullanılmaz; yeni kontrol eklenmeden önce `InputPolicy` genişletilir.
4. **Dalga 4 — hız ve eğlence:** S62–S80. Her oyun önce "sessiz/prototip" modda doğrulanır; ses, haptik, 3B varlık ve sonuç kutlaması mekanik oturduktan sonra eklenir.
5. **Dalga 5 — yayın öncesi denge:** tüm oyunlarda günlük görev rotasyonu, Arena seçki havuzu, cihaz performansı, Türkçe/İngilizce içerik ve mağaza görselleri ölçülür.

## Tekrara düşmeme matrisi

- Aynı haftada yalnız bir ana kontrol biçimi yayınlanır: sürükleme, dokunma, kaydırma, sıralama, serbest yerleştirme veya ritim.
- Aynı başarısızlık modeli art arda gelmez: süre bitti, hamle bitti, kural ihlali, yanlış hedef, fizik denge kaybı, çözüm kilidi.
- Aynı görsel metafor en fazla üç oyunda kullanılır; örneğin blok, kart, tüp ve küp ailesi kendi içinde farklı malzeme/amaç taşır.
- Yeni oyun ancak benzersiz `GameAudioProfile` tablosu onaylandığında üretime girer. “correct.wav her yere” yalnız prototipte kabul edilir; yayın adayında tür kimliği taşıyan varyant gerekir.
- Yeni oyun mevcut bir oyunun ekranını, skor anahtarını, günlük görev kimliğini veya seviye kaydını değiştiremez. Her yeni oyun kendi `gameId`, progress prefix, analitik olayı, ses grubu ve içerik seed alanına sahip olur.

## Yayın kriteri

80 oyunun tamamı aynı anda açılmaz. Her oyun kendi sprintinde feature flag arkasında, dahili test → küçük kullanıcı grubu → kademeli açılış sırasıyla yayınlanır. Ölçülecek sinyaller: ilk bölüm tamamlama, ilk hata sonrası tekrar deneme, ipucu kullanımı, seans süresi, FPS düşüşü, dokunma iptali, ses kapatma oranı ve çökme oranı. Hedefe ulaşmayan oyun bir sonraki oyuna geçilmeden önce kendi sprintinde düzeltilir.
