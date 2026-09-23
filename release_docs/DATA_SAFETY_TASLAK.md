# Google Play Data Safety — Kaynak Koddan Çıkarılan Taslak

Bu belge Play Console formunun yerine geçmez. Son beyan, kullanılan Firebase SDK'larının güncel Data Safety dokümantasyonu ve gerçek üretim davranışıyla karşılaştırılmalıdır.

## Kodda görülen veri akışları

### Cihazda yerel saklama

- Oyun ilerlemesi, yıldızlar ve skor özetleri
- Dil/erişilebilirlik/ses/oyun tercihleri
- Günlük görev ve seri bilgileri

### Firebase Authentication

- Uygulama e-posta/telefon istemeden **anonim Firebase kullanıcı hesabı** açar.

### Cloud Firestore

- anonim UID
- oyuncu adı ve avatar
- skor, yıldız, bölüm/ilerleme özetleri
- friend code ve sosyal düello kayıtları
- Arena grup üyelikleri, yarışma/deneme sonuçları
- FCM cihaz tokenı ve locale/platform bilgisi

### Firebase Analytics

Kodda görülen olay/özellik örnekleri:

- app open / screen view
- game_open
- level_complete (game_id, stars, score, daily_tasks, streak)
- language_change
- profile_edit
- player_level_group, league, app_language user properties

### Firebase Crashlytics

- Yalnız release build'de etkin
- Firebase UID veya oyuncu adı user identifier olarak eklenmiyor
- `last_area`, level group, league ve app language gibi teknik/segment bağlamı bulunabilir
- hata ve stack trace raporları işlenebilir

### Firebase Cloud Messaging

- cihaz bildirim tokenı Firestore'da `player_devices_v1/{uid}` altında saklanır
- düello/Arena bildirimleri için kullanılır

### Firebase App Check / Play Integrity

- Firebase kaynaklarını kötüye kullanımdan korumak için cihaz/uygulama bütünlük doğrulaması kullanılır.

## Muhtemel Play Console kategorileri

Gerçek formdaki tanımlarla yeniden doğrulayın:

- **App activity:** oyun açma, ekran görüntüleme, bölüm tamamlama gibi analytics olayları
- **App info and performance:** Crashlytics hata/performans tanılama bilgileri
- **Device or other IDs:** Firebase/FCM tarafındaki teknik tanımlayıcılar ve tokenlar SDK sınıflandırmasına göre değerlendirilmeli
- **User IDs:** anonim Firebase UID, çevrim içi hizmetlerde kullanıcı kimliği olarak kullanılır
- **User-generated content / Other info:** oyuncu tarafından seçilen görünen ad/avatar Play formundaki uygun kategoriye göre sınıflandırılmalı

## Kullanım amaçları

- App functionality
- Analytics
- Fraud prevention / security (App Check)
- Developer communications / notifications yalnız oyun daveti ve sonuç bildirimi bağlamında değerlendirilmeli

## Paylaşım

- Oyuncu adı/avatarı ve bazı skor/sıralama bilgileri diğer oyunculara gösterilir.
- Firebase/Google altyapısının “service provider” niteliği Play Data Safety tanımına göre ayrıca değerlendirilmelidir.

## Silme

V12 ile Ayarlar → Gizlilik ve veri ekranından çevrim içi anonim profil için silme isteği oluşturulur. Functions dağıtımı yapılmış olmalıdır.

## Yayın öncesi doğrulanacaklar

- [ ] Firebase SDK Index'teki güncel Data Safety bilgileri kontrol edildi
- [ ] Analytics açık/kapalı davranışı gerçek release'te doğrulandı
- [ ] Crashlytics yalnız release'te veri gönderiyor
- [ ] FCM tokenı yalnız bildirim özelliği için kullanılıyor
- [ ] Gizlilik politikası beyanı Play Data Safety formuyla çelişmiyor
- [ ] Destek e-postası ve veri silme yolu çalışıyor
