# Alt Oyun Görselleri Uygulama ve QA Raporu

Tarih: 11 Ekim 2026

## Kapsam

- Ana sayfa görsellerine dokunulmadı.
- Sekiz alt kategori için neon azaltılmış, soğuk ve koyu yeşil ağırlıklı son konsept setleri projeye alındı.
- Kategori sayfalarındaki oyun kartları, oyun kimliğine göre ilgili görsel paneline bağlandı.

## Eklenen varlıklar

`assets/branding/game_catalog/` altında:

- `logic_sheet.png`
- `numbers_sheet.png`
- `visual_sheet.png`
- `memory_sheet.png`
- `strategy_sheet.png`
- `language_sheet.png`
- `speed_sheet.png`
- `fun_sheet.png`

Toplam: 8 görsel, yaklaşık 18.96 MB.

## Eşleştirme

`lib/widgets/studio_game_artwork.dart` içindeki katalog eşlemesiyle 64 oyun kimliği, hazırlanan kategori panellerine bağlandı. Harita oyunları (`city_atlas`, `world_atlas`) ve özel/legacy oyun kimlikleri mevcut deterministik çizimlerine bırakıldı.

## Görsel QA kuralları

- Neon bloom, lazer parlaması ve dekoratif ışık izleri azaltıldı.
- Oyun mekaniğini anlatan küçük seçim/aktiflik vurguları korundu.
- Koyu yeşil, petrol, lacivert, kobalt, zümrüt, mor, camgöbeği ve mercan paleti korundu.
- Gerçekçi ahşap, cam, seramik, kâğıt, kumaş, metal ve mat polimer yüzeyleri kullanıldı.
- Altın/bronz ve sıcak sepya ışıklandırma baskın olmayacak şekilde sınırlandı.
- Hafıza kategorisi, yanlış kırpma riskini önlemek için kesin 2×4 panelli son sürümle değiştirildi.

## Kontroller

- Sekiz kategori dosyasının tamamı disk üzerinde mevcut.
- Kaynak içindeki tüm kategori asset yolları mevcut dosyalara karşı kontrol edildi.
- Görsel eşleme kaynağında parantez/köşeli parantez/süslü parantez dengesi kontrol edildi.
- `git diff --check` temiz; yalnızca mevcut çalışma alanındaki satır sonu uyarıları görüldü.
- Flutter `analyze`, `pub get` ve hedefli test komutları bu ortamda çıktı üretmeden uzun süre kilitlendiği için son derleme sonucu doğrulanamadı. Bu durum kaynak kod veya asset hatası olarak yorumlanmadı; yeniden çalıştırılabilir ortam testi gereklidir.

## Değişen dosyalar

- `lib/widgets/studio_game_artwork.dart`
- `pubspec.yaml`
- `assets/branding/game_catalog/*.png`

