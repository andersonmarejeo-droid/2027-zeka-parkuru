# Eğlence Kategorisi — Aktif Katalog Kararı

Tarih: 2 Ekim 2026

Son kalite elemesinde beş oyun daha oyuncuya açık katalogdan çıkarıldı; Şeker Konveyörü de Eğlence'den Hız ve Tepki sınıfına taşındı. Bu nedenle Eğlence sınıfında dört oyun aktif kaldı. “Füzyon Odası” bölüm adı, ayrı bir oyun değil Top Birleştir'in (`ball_merge`) bölüm adıdır; bu tek oyun olarak emekliye ayrıldı. Kaynak klasörleri, seviye/puan SharedPreferences anahtarları, analitik geçmişi ve eski skorlar silinmedi. Böylece ilerleme verisi korunur ve oyunlar ileride yeniden değerlendirilip kontrollü biçimde geri alınabilir.

## Eğlence sınıfında aktif kalan 4 oyun

| Oyun | Ana oynanış türü |
|---|---|
| Mini Golf Rota | Açı, güç ve parkur engelleriyle atış planlama |
| Drift Ligi | Yarış çizgisi ve drift kontrolü |
| Air Hockey Arena | Rakibe karşı gerçek zamanlı konum ve vuruş kararı |
| Gizli Oda: Sosyal Çıkarım | İpucu birleştirme ve rol çıkarımı |

Şeker Konveyörü artık **Hız ve Tepki** sınıfında listelenir; ilerleme anahtarı değişmedi.

## Aktif katalogdan çıkarılan 35 oyun

Blok Akışı, Balon Avcısı, Şişe Kırmaca, Renk Reaktörü, Kule Denge, Mıknatıs Rotası, Halka At, Küçük Balıkçı, Mermer Rota, Kâğıt Uçak Şampiyonası, Ritim Atölyesi, Uçurtma Pilotu, Kaykay Akışı, Kar Sörfü Slalomu, Jetpack Kurye, Yörünge Kurtarma, Masa Tenisi Rallisi, Penaltı Zihin Oyunu, Kalıntı Seferi, Müze: Gece Vardiyası, Derin Akıntı, Kafe Vardiyası, İç Mekân Atölyesi, Deniz Camı Akvaryumu, Dostlar Kurtarma Kliniği, Ay Üssü Operasyonları, Müze Küratörü, Festival Yapımcısı, Zar ve Hançer, Sinyal Ortağı, Top Birleştir / Füzyon Odası, Neon Pinball, Fener Savunması, Sahil Parkı Kurucusu, Deste Ustası.

## Güvenlik kapsamı

- Eğlence sınıfında aktif oyun sayısı 10'dan 4'e indi. Ardından kullanıcı seçimiyle 13 oyun daha aktif katalogdan çıkarıldı; genel aktif oyun sayısı 64'ten 51'e indi.
- Kategori listeleri ve ana sayfa önerileri emekliye alınan oyunları göstermez.
- Eski bir bağlantı veya kayıtlı oyun numarasıyla doğrudan açma denemesi de engellenir.
- Eski oyun kodu ve yerel ilerleme verileri silinmez; diğer kategorilerin puanlama ve kayıt anahtarlarına dokunulmaz.

## Sonraki katalog elemesi: 13 oyun

Depo Ustası, Tavla Ustası, Go Yaşam-Ölüm, Shogi Mat, Tek Taş, Hex Bağlantısı, Mahjong Katmanları, Mantık Labirenti, Akış Bağlantısı, Devre Tamiri, Köprü Kur, Kapı Dizisi ve Kod Kırıcı kullanıcı isteğiyle aktif katalogdan çıkarıldı. Bu başlıkların eski puan/ilerleme anahtarları korunur; uygulama içindeki kategori, öneri ve oyun açma akışlarında görünmezler.
