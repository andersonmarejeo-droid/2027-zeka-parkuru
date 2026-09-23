# Günlük Parkur Akış Düzeltmesi

## V2 kurulum düzeltmesi

V1 paketindeki kaynak kopyaları `.dart` uzantısı taşıdığı için paket proje
köküne çıkarıldığında `flutter analyze` bu yedekleri de uygulama dosyası sanıyordu.
V2 aynı kaynak içeriğini `.dart.zpdata` olarak taşır ve hedefe kopyalarken gerçek
dosya adını kullanır. Bu değişiklik uygulama mantığını değiştirmez; yalnız kurulum
doğrulamasındaki sahte import hatalarını kaldırır. Eski V1 klasörü bulunursa
analizden önce Windows TEMP içindeki geri alma klasörüne taşınır.

## Yeni ortak sözleşme

Günlük Parkur artık oyunların normal seviye ilerlemesini yönetmesine güvenmez.
Her oyun merkezi, yalnızca `dailyCourseMode` açıkken yerel oyun sonucunu şu dört
durumdan birine çevirir:

| Durum | Rotaya etkisi | Ödül |
|---|---|---|
| `completed` | Bölüm çözülür, sonraki istasyon hazırlanır | Yıldız + günlük Zeka Puanı |
| `failed` | Bölüm çözülür, rota devam eder | 0 yıldız, 0 puan |
| `skipped` | Kullanıcı onayıyla bölüm çözülür | 0 yıldız, 0 puan |
| `exited` | Bölüm çözülmez; aynı oyun sırada kalır | Kayıt yok |

## Oyun köprüleri

- Doğrudan köprü: Mantık, Sayılar, Bloklar, Hafıza, Hanoi ve Refleks.
- Ortak `ParkurLevelHub` köprüsü: Kelime Avı, Görsel IQ, Şeker Sıralama,
  Sayı Peteği ve Şekil Birleştir.
- Hafıza oyunundaki `completed: true, stars: 0, score: 0` can tükenmesi,
  yalnız Günlük Parkurda `failed` kabul edilir.
- Mantık ve Refleksin yerel `completed: false` sonuçları `failed` kabul edilir.
- Diğer modların `DailyCourseGameResult` sözleşmesi değiştirilmemiştir.

## Güvenlik önlemleri

- Günlük rota kaydı tek JSON durumunda atomik olarak saklanır.
- Aynı oyun iki defa puanlanmaz; eşzamanlı kayıtlar sıraya alınır.
- Gece yarısından önce açılan sonuç ertesi günün rotasına yazılmaz.
- Eski V1/V2 günlük kayıtları aynı gün için V3 yapısına taşınır.
- Aynı tarih + oyun + tur, aynı seviye ve aynı düzen kodunu üretir.
- Geçiş penceresinde Android geri tuşu `false` döndürüp otomatik zinciri durdurur.
- Yükleme hatası sonsuz gösterge yerine tekrar deneme ekranı gösterir.
- Bilinmeyen oyun kimliği boş widget yerine görünür güvenli hata ekranına gider.

## Müdahale edilmeyen alanlar

- Oyunların `PlayPage` motorları ve özgün soru/hamle kuralları
- Bire bir düello ve grup yarışı
- Normal oyun kayıtları ve seviye açma kuralları
- Firebase, Android, Gradle, pubspec ve yayın ayarları
- Hanoi kayıt/geri yükleme motoru
