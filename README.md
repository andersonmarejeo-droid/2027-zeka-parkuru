# Zekâ Parkuru

Flutter + Firebase tabanlı; 11 oyun, 110 bölüm, 330 yıldız, günlük görevler, Zekâ Puanı, rozetler, dünya sıralaması ve sosyal yarışmalar içeren mobil oyun.

**Güncel yayın adayı:** `1.7.0+15`  
**Toplu sertleştirme:** V12  
**Görsel IQ motoru:** V11.5 çeşitlilik + tek-doğru-cevap garantisi

## Oyunlar

Mantık Labirenti, Sayı Ustası, Blok Atölyesi, Hafıza Labirenti, Hanoi Kulesi, Kelime Avı, Görsel IQ, Şeker Sıralama, Sayı Peteği, Şekil Birleştir ve Refleks Avı.

## Zekâ Arenası

- Bildirimli 1'e 1 refleks düellosu
- 2–30 kişilik özel gruplar
- Kod ve HTTPS davet bağlantısıyla katılım
- 11 oyunun tamamıyla tek oyun veya çoklu parkur yarışı
- Ortak seviye ve ortak parkur düzeni
- Canlı sıralama ve ilk üç kürsüsü

Normal oyunlar çevrimdışı çalışır. Grup, davet, canlı sıralama ve dünya sıralaması için internet bağlantısı gerekir.

## Yerel geliştirme

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```

## Tek komut kapsamlı kontrol

```powershell
powershell -ExecutionPolicy Bypass -File .\KAPSAMLI_TEST.ps1
```

Script; release preflight, pub get, analyze, mevcut testlerin tamamı, debug APK ve Firebase Functions JavaScript kontrolünü çalıştırır. Test sayısı artık dosyalardan dinamik hesaplanır.

Release signing tamamlandıktan sonra:

```powershell
powershell -ExecutionPolicy Bypass -File .\KAPSAMLI_TEST.ps1 -Release
```

veya yalnız AAB hattı:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ZP_RELEASE_AAB.ps1
```

USB ile kurulmuş yerel bir **release APK** üzerinde Firebase App Check
denemesi yapılacaksa, Play Integrity kararı alınamayacağı için önce Firebase
Console'da bu uygulama için debug token kaydedilmeli ve yalnızca QA derlemesi
şu ek tanımla alınmalıdır:

```powershell
flutter build apk --release --dart-define=FIREBASE_APP_CHECK_DEBUG=true
```

Bu tanım Play Console'a yüklenecek AAB'de kullanılmamalıdır. Üretim AAB'si
varsayılan olarak Play Integrity kullanır.

## Android / Play Store

- `compileSdk = 36`
- `targetSdk = 36`
- Release debug anahtarıyla imzalanmaz.
- Gerçek upload keystore proje dışında saklanır.
- `android/key.properties.example` yalnız şablondur.

Var olan keystore'u bağlamak için:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ZP_CONFIGURE_SIGNING.ps1 -StoreFile "C:\keys\zeka-parkuru-upload.jks"
```

## Firebase dağıtımı

```powershell
firebase deploy --only firestore:rules,firestore:indexes,hosting
firebase deploy --only functions
```

Functions; FCM düello/Arena bildirimlerinin yanında V12 ile uygulama içi çevrim içi veri silme isteğini de işler. Bu nedenle üretim öncesi Functions deploy kritik kabul edilir.

## Gizlilik

- Ayarlar → Gizlilik ve veri ekranı uygulama içi politikayı gösterir.
- `hosting/privacy.html` Play Console gizlilik politikası URL'si için hazırlanmıştır.
- Yayın öncesi destek e-postasını doldurun:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ZP_SET_SUPPORT_EMAIL.ps1 -Email "destek@example.com"
```

## App Links

Play App Signing SHA-256 alındıktan sonra:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ZP_FINALIZE_APP_LINKS.ps1 -Sha256 "AA:BB:..."
```

Bu işlem `hosting/.well-known/assetlinks.json` oluşturur ve HTTPS intent filter'larında `autoVerify=true` yapar. Ardından Hosting'i yeniden deploy edin.

## Yayın planı

Detaylı sıra ve hangi adımların otomatik/hangi adımların Play/Firebase hesabı gerektirdiği için:

- `release_docs/V12_TOPLU_DUZELTME_MIMARISI.md`
- `release_docs/DATA_SAFETY_TASLAK.md`
- `release_docs/GERCEK_CIHAZ_TEST_MATRISI.md`
