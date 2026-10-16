# 30 bölüm / 300 içerik standardı

Sürüm: **1.8.7+23**. Tarih: **5 Ekim 2026**.

## Kullanıcıya görünen düzen

- Katalogdaki 46 aktif oyunun her birinde 30 bölüm kartı bulunur.
- Bölümler başlangıç, gelişim, ileri, uzman ve usta olarak altışarlı gruplara ayrılır.
- Her bölüm 10 ayrı havuz adresine sahiptir: 30 × 10 = 300 içerik.
- İç havuz menüde 300 kart veya ayrı bir uzun liste olarak gösterilmez.
- Bölüm tekrar oynandığında kendi on varyasyonundan sonraki içerik seçilir. Onu tüketince döngü başa döner; sonlu havuz sonsuz tekrar etmeme garantisi vermez.
- Bölüm numarası ile eski oyun motorunun zorluk şablonu ayrıdır. 10/20 şablonlu motorlarda zorluk başa dönmeden 30 bölüme yayılır.
- Günlük parkurun bölüm seçimi de 1–30 aralığındadır. Mevcut çevrimiçi düello kurallarını bozmamak için düello üretiminin mevcut aralığı korunmuştur.

## Kayıt koruma

- Eski yıldız/puan anahtarları değiştirilmedi, uygulama verisi temizlenmedi.
- Hatalı 300-açık kayıtlarında, ardışık tamamlanmış bölüm kayıtlarından güvenli açık bölüm sayısı hesaplanır.
- Ortak bölüm kaydı, 30'dan sonraki eski kayıtları silmek yerine arşiv kuyruğunda saklar.
- Aktif kampanya kapasitesi 1.380 bölüm / 4.140 yıldızdır.
- Kaldırılmış iki eski parkurun ödülleri yaşam boyu toplamda korunur; aktif kampanya yüzdesine katılmaz.

## İçerik ve performans

- KenKen, Mayın Dedektifi, Park Yeri, Hedef 24 ve sekiz doğrulanmış bulmaca için toplam 12 hazır içerik bankası paketlendi.
- Bu bankalar 1.012.119 bayttır; yalnızca açılan oyunun bankası yüklenir.
- Yeni bölüme girişte pahalı çözüm araması yerine hazır verinin okunması kullanılır. Diğer oyunlar küçük, belirli tohumlu üreticilerini kullanır.
- Hanoi'nin 300 farklı yasal başlangıç durumu, hedefe uzaklığı çözümleyiciyle ölçülerek sıralanır.
- Dedektif Notları'nda doğrudan verilen bilgiler beş kademede azalır; her vaka yine tek çözümle doğrulanır.
- Kelime Çarkı, Gizli Kütleler ve Kakuro için farklı oynanabilir içerik havuzları eklendi.
- Bölüm geçiş kuyruğunun tamamlanmış işlemlerini tutması nedeniyle oluşan bekleme düzeltildi; yükleme hatasında yeniden deneme mümkündür.

## Doğrulama

- 96 dosyada 409 mevcut aktif-oyun/regresyon testi geçti.
- 94 ekran testi geçti: tüm 46 menüde tam 30 kart; tüm oyunların ilk ve 30. bölümleri; dar ekran ve büyük yazı; görsel çıktılar.
- Son kaynak üzerinden ekranlar ve kayıt kuyruğunun birlikte yürütüldüğü 99 kontrole ait son test turu da geçti (`campaign30-final-results.json`).
- 19 havuz/kayıt testi geçti: 46 oyun için 300 adresin birebir dağılımı; onlu tekrar sırası; kayıt göçü; Hanoi çözüm mesafeleri; ek model havuzlarında 300 içerik tekilliği.
- Dedektif'in 300 ilerlemeli vakası ayrıca tek-çözüm kontrolünden geçti.
- 12 paket bankasının serileştirme/yükleme geri dönüşü doğrulandı.
- Görsel çıktılar `build/visual_sprint` altında, makine okunur sonuçlar `build/campaign30-*-results.json` dosyalarındadır.

## Sınırlar

- Otomatik ekran testleri fiziksel telefonda tüm bölümlerin insan tarafından oynanmasının yerine geçmez.
- Bu sprint telefona kurulum, mağazaya gönderim veya üretim sunucusuna kural yayını yapmaz.
- Mevcut Firestore V3 sıralama alanlarının eski 330 yıldız / 110 tamamlanan bölüm üst sınırı bu sprintte korunmuştur; sunucu şeması göçü ayrı yayın gerektirir. Yerel kampanya ilerlemesi bu sınıra bağlı değildir.
- Analizde, bu sprint dışındaki emekli Baloncuk oyunu ve eski menü bileşenine ait beş mevcut uyarı/bilgi bulunur; kaynak hatası yoktur.

## Android paketi

- Üretim başarılı: `build/app/outputs/flutter-apk/app-release.apk`.
- Paket: `com.mustafapolat.zeka_parkuru`, sürüm adı **1.8.7**, sürüm kodu **23**.
- Dosya boyutu: **105.668.388 bayt** (100,8 MiB).
- Üretim zamanı: **5 Ekim 2026, 19:31 Türkiye saati**.
- APK Signature Scheme v2 imzası doğrulandı; tek imzacı.
- APK arşivi içindeki 12 hazır bankanın her birinde tam 300 kayıt doğrulandı.
- SHA-256: `F483B8D4BEF9C2F4EB50FC2DDAF6C6813B10A7D31F6B9FB1A6AAD0804541D51F`.
- Fiziksel telefona kurulum yapılmadı; mevcut telefon verileri değiştirilmedi.
