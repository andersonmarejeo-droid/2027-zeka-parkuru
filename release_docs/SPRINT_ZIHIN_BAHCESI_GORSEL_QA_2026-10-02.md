# Zihin Bahçesi — Tema ve Görsel QA Sprinti

Tarih: 2 Ekim 2026  
Kapsam: aktif oyunların açılışı, tema bütünlüğü, sıralama/arkadaş ekranları ve dar ekran yerleşimleri.

## Sprint hedefi

Zihin Bahçesi açık temasının oyun girişlerinde ve uygulama sayfalarında tutarlı çalıştığını doğrulamak; özellikle liderlik, arkadaş ve meydan okuma akışlarında kalan eski neon/koyu görsel parçaları sakin bahçe paletine taşımak. Oyun mantığı, puanlama, arkadaş verisi ve kayıt anahtarları bu sprintte değiştirilmez.

## İş paketleri ve kabul ölçütleri

### 1 — Tema ve ekran envanteri

- Tek aktif tema kaynağını (`studio_garden`) ve `ZpVisualPalette.garden` değerlerini kontrol et.
- Ana sayfa, sekiz kategori, oyun başlangıç/oyun tahtası/sonuç ekranı, görevler, liderlik, arkadaşlar, Arena, profil, ayarlar ve gizlilik ekranlarını envantere ekle.
- Kategori rengi ile ortak yüzey/zemin renklerini ayır: kategori vurguları kimliği korur; kabuk ve metin kontrastı tema token’larından gelir.
- Kabul: alternatif kayıt değerleri seçilemesin; eski mavi/pembe tema ana akışlarda görünmesin.

### 2 — Oyun açılışı ve yerleşim doğrulaması

- Aktif katalogdaki oyunların giriş rotalarını ve oyun sayfası yapıcılarını karşılaştır.
- Her oyun sayfasını Zihin Bahçesi paleti yüklü açık temada aç; Flutter istisnası, taşma ve eksik tema uzantısı kontrolü yap.
- 320×600 telefon ve 800×1280 tablet boyutlarında Türkçe/İngilizce duman testini çalıştır.
- Kabul: bütün aktif oyun ekranları açılır; dar ekranda yatay taşma/Flutter hatası oluşmaz. Oyun tahtasının oynanış için gereken yüksek kontrastı korunabilir.

### 3 — Liderlik ve kişisel skorlar

- Lig özeti, kişisel ilk üç, oyun bazlı ilerleme ve dünya sıralamasını aynı yüzey hiyerarşisine bağla.
- Neon renkleri sınıf aksanlarına indir; kart, metin, boş durum, çevrimdışı ve önbellek uyarılarında okunabilir kontrastı koru.
- Kabul: birincil metin koyu mürekkep, açıklamalar muted, yüzeyler beyaz/açık; altın/teal yalnızca anlamlı vurgu.

### 4 — Arkadaş ve meydan okuma akışı

- Davet/arkadaş kodu, meydan okumalarım, arkadaş sıralaması, aktif oyuncular ve dünya listesi durumlarını denetle.
- Yükleniyor, boş, çevrimdışı, hata ve dolu durumlarını aynı kart/ikon/başlık sistemiyle ele al.
- Kabul: açık zeminde beyaz metin kalıntısı veya okunmayan buton bulunmasın; davet ve meydan okuma eylemleri görsel önceliğini korusun.

### 5 — Arena ve sonuç ekranları

- Grup, sezon, etkinlik, maç, sıralama ve sonuç kartlarını ayrı ayrı tarayıp oyun alanının dramatik vurgusunu menü kabuğundan ayır.
- Kabul: oyun içi yüksek kontrast/sonuç vurguları kalabilir; gezinme, bilgi ve liste yüzeyleri Zihin Bahçesi ile aynı görsel dili kullanır.

### 6 — Profil, görevler ve geçmiş

- Profil ilerlemesi, günlük görev/seri, tamamlanma özeti ve mevcut sonuç/geçmiş bileşenlerini denetle.
- Gerçek bir oyun geçmişi ekranı bulunmuyorsa yeni veri uydurma; mevcut sonuç ve ilerleme kartlarını düzenle, ayrı geçmiş özelliğini sonraki ürün kararı olarak işaretle.
- Kabul: yıldız, seviye, skor ve tamamlanma metrikleri tutarlı sırada ve okunabilir boyutta görünür.

### 7 — Erişilebilirlik ve son regresyon

- 320/360 dp telefon, tablet, Türkçe/İngilizce, uzun adlar, büyük metin ve yükleniyor/boş/hata durumlarını tekrar çalıştır.
- Ana kategori kartının tamamına dokunma, geri gezinme ve eski tema kayıtlarından varsayılan temaya dönüşü regresyonla koru.
- Kabul: hedefli Flutter testleri ve oyun duman testi geçer; ses/ağ altyapısı bulunmaması UI testini başarısız göstermeden sessiz fallback verir.

## Bu çalışmada uygulananlar

- Tema sözleşmesi yalnız `studio_garden`; eski tema kayıtları da güvenli biçimde bu temaya düşüyor. İlk kurulum, ana sayfa, kategori, ayarlar ve uygulama kabukları aynı açık zemin/teal vurgusunu kullanıyor.
- Liderlik/sıralamada kişisel lig özeti, kişisel podyum, oyun skorları, dünya özeti, güncel oyuncu satırı ve çevrimdışı/önbellek durumları açık kart hiyerarşisine taşındı.
- Arkadaş/meydan okuma akışında davet, kod, oyuncu, düello, skor ve boş/çevrimdışı durumları aynı yüzey, tipografi ve ikon sistemine alındı.
- Arena grup, haftalık lig, yarışma, oyun listesi, podyum ve sonuç kartlarının kabukları Zihin Bahçesi paletine uyarlandı. Oyunların kendine özgü tahtalarındaki gerekli yüksek kontrast korundu.
- Profildeki özel rozetler, başarılar ve oyun istatistikleri; günlük görev/parkur/sonuç ekranları; ayarlar ve gizlilik ekranları da aynı açık yüzey ailesine bağlandı.
- Bağımsız bir oyun geçmişi sayfası bulunmuyor. Var olan profil ilerlemesi ve skor dökümü düzenlendi; yeni veri modeli/özelliği uydurulmadı.
- Görsel değişiklikler dışında oyun kayıtları, puanlama, sosyal/Arena verileri ve oyun oturum akışı değiştirilmedi.

## Son kontrol listesi

- [x] Katalog sözleşmesinde 69 oynanabilir oyun ve sekiz ana kategori doğrulandı.
- [x] 108 oyun ekranı/kartı yapıcısı 320×600 Türkçe telefonda ve 800×1280 İngilizce tablette açıldı; Flutter hatası/yerleşim istisnası oluşmadı.
- [x] Sekiz ana kategoriye dokunma ve oyun kataloğuna dönüş testi geçti.
- [x] Liderlik, arkadaş/meydan okuma, Arena, günlük rota, profil, ilk kurulum, ayarlar ve gizlilik yüzeyleri tarandı.
- [x] Günlük rota akış ve tema sözleşmesi regresyonları geçti.
- [x] Etkilenen Dart dosyalarının statik analizi: sorun yok.
- [x] `git diff --check` temiz.

### Doğrulama notları

Hedefli UI/akış testleri 21/21, katalog ve içerik sınıflandırma testleri 4/4 geçti (toplam 25). Windows test ortamında `flutter_soloud_plugin.dll` bulunmadığı için ses servisi sessiz yedek davranışına geçti; bu beklenen ve güvenli bir test fallback'i. Çevrimiçi liderlik yeniden bağlanma zaman aşımı da çevrimdışı test ortamı uyarısıdır; test sonucu başarısız olmadı.
